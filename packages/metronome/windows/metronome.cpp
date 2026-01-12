#include "metronome.h"
#include <cmath>
#include <iostream>
#include <vector>
#include <cstdint>
#include <stdexcept>
#include <cstring>
#include <thread>
#include <atomic>
#include <chrono>
#include <string>

Metronome::Metronome(HWND window, const std::vector<uint8_t> &mainFileBytes,
                     const std::vector<uint8_t> &accentedFileBytes,
                     int bpm, int timeSignature, double volume, int sampleRate)
    : windowHandle(window), audioBpm(bpm), audioTimeSignature(timeSignature), audioVolume(volume), sampleRate(sampleRate)
{
    if (mainFileBytes.empty())
    {
        throw std::invalid_argument("Main sound file cannot be empty");
    }

    mainSound = byteArrayToShortArray(mainFileBytes);
    accentedSound = accentedFileBytes.empty() ? mainSound : byteArrayToShortArray(accentedFileBytes);

    InitializeAudio();
    audioBuffer = generateBuffer();
}

Metronome::~Metronome()
{
    Destroy();
}

void Metronome::Play()
{
    if (!playing.exchange(true))
    {
        audioBuffer = generateBuffer();
        if (hWaveOut)
        {
            waveOutRestart(hWaveOut);
        }
        metronomeThread = std::thread(&Metronome::StartMetronome, this);
    }
}

void Metronome::Pause()
{
    if (playing.exchange(false))
    {
        // Notify thread to wake up immediately
        stopCV.notify_all();

        if (metronomeThread.joinable())
        {
            metronomeThread.join();
        }

        if (hWaveOut)
        {
            waveOutReset(hWaveOut);
        }
        currentTick = 0;
        writeCursor = playCursor = 0;
    }
}

void Metronome::Stop()
{
    if (playing.exchange(false))
    {
        // Notify thread to wake up immediately
        stopCV.notify_all();

        if (metronomeThread.joinable())
        {
            metronomeThread.join();
        }

        if (hWaveOut)
        {
            waveOutReset(hWaveOut);
        }
    }
}
void Metronome::SetBPM(int bpm)
{
    if (audioBpm != bpm)
    {
        bool wasPlaying = IsPlaying();
        if (wasPlaying)
        {
            Pause();
        }
        audioBpm = bpm;
        if (wasPlaying)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            Play();
        }
    }
}
void Metronome::SetTimeSignature(int timeSignature)
{

    if (audioTimeSignature != timeSignature)
    {
        bool wasPlaying = IsPlaying();
        if (wasPlaying)
        {
            Pause();
        }
        audioTimeSignature = timeSignature;
        if (wasPlaying)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            Play();
        }
    }
}

void Metronome::SetVolume(double volume)
{
    if (volume < 0.0 || volume > 1.0)
    {
        throw std::invalid_argument("Volume must be between 0.0 and 1.0");
    }

    audioVolume = volume;
    if (hWaveOut)
    {
        DWORD vol = static_cast<DWORD>(0xFFFF * volume);
        waveOutSetVolume(hWaveOut, vol | (vol << 16));
    }
}

void Metronome::SetAudioFile(const std::vector<uint8_t> &mainFileBytes,
                             const std::vector<uint8_t> &accentedFileBytes)
{

    if (!mainFileBytes.empty() || !accentedFileBytes.empty())
    {
        bool wasPlaying = IsPlaying();
        if (wasPlaying)
        {
            Pause();
        }
        if (!mainFileBytes.empty())
        {
            mainSound = byteArrayToShortArray(mainFileBytes);
        }
        if (!accentedFileBytes.empty())
        {
            accentedSound = byteArrayToShortArray(accentedFileBytes);
        }

        if (wasPlaying)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            Play();
        }
    }
}
int Metronome::GetVolume() const
{
    return static_cast<int>(audioVolume * 100);
}
bool Metronome::IsPlaying() const
{
    return playing.load();
}

void Metronome::EnableTickCallback(std::function<void(int)> callback)
{
    this->tickCallback = callback;
}

std::vector<int16_t> Metronome::byteArrayToShortArray(const std::vector<uint8_t> &byteArray)
{
    if (byteArray.empty() || byteArray.size() % 2 != 0)
    {
        throw std::invalid_argument("Invalid byte array length for PCM_16BIT");
    }

    std::vector<int16_t> shortArray(byteArray.size() / 2);
    std::memcpy(shortArray.data(), byteArray.data(), byteArray.size());
    return shortArray;
}

std::vector<int16_t> Metronome::generateBuffer()
{
    std::lock_guard<std::mutex>
        lock(paramMutex);
    int newBeatLength = static_cast<int>(sampleRate * 60.0 / audioBpm);
    std::vector<int16_t> bufferBar;
    if (audioTimeSignature < 2)
    {
        bufferBar.resize(newBeatLength, 0);
        std::copy_n(mainSound.begin(), min(newBeatLength, static_cast<int>(mainSound.size())), bufferBar.begin());
    }
    else
    {
        int beats = max(1, audioTimeSignature);
        bufferBar.resize(newBeatLength * beats, 0);
        for (int i = 0; i < beats; i++)
        {
            const std::vector<int16_t> &sound = (i == 0) ? accentedSound : mainSound;
            int copyLength = min(newBeatLength, static_cast<int>(sound.size()));
            std::copy_n(sound.begin(), copyLength, bufferBar.begin() + i * newBeatLength);
        }
    }

    beatLength = newBeatLength;

    return bufferBar;
}

void Metronome::InitializeAudio()
{
    WAVEFORMATEX wfx = {0};
    wfx.wFormatTag = WAVE_FORMAT_PCM;
    wfx.nChannels = 1;
    wfx.nSamplesPerSec = sampleRate;
    wfx.wBitsPerSample = 16;
    wfx.nBlockAlign = 2;
    wfx.nAvgBytesPerSec = sampleRate * 2;

    MMRESULT result = waveOutOpen(&hWaveOut, WAVE_MAPPER, &wfx,
                                  reinterpret_cast<DWORD_PTR>(this->windowHandle),
                                  reinterpret_cast<DWORD_PTR>(this),
                                  CALLBACK_WINDOW);

    if (result != MMSYSERR_NOERROR)
    {
        throw std::runtime_error("Failed to initialize audio device. Error: " + std::to_string(result));
    }
    SetVolume(audioVolume);
}

void Metronome::ProcessBuffer(WAVEHDR *hdr) 
{
    if (hdr)
    {
       waveOutUnprepareHeader(hWaveOut, hdr, sizeof(WAVEHDR));
       delete[] hdr->lpData;
       delete hdr;
    }
    
    // Only process ticks if we are playing or in valid state
    if (playing.load()) {
        std::lock_guard<std::mutex> lock(bufferMutex);
        playCursor += beatLength;
        //
        if (tickCallback)
        {
            if (audioTimeSignature < 2)
            {
                currentTick = 0;
            }
            else
            {
                currentTick++;
                if (currentTick >= audioTimeSignature)
                    currentTick = 0;
            }
            tickCallback(currentTick);
        }
    }
}

// WaveOutProc removed

void Metronome::PlaySound()
{
    if (!IsPlaying())
        return;

    //
    WAVEHDR *hdr = new WAVEHDR{0};
    int16_t *buffer = new int16_t[beatLength];

    //
    size_t currentWriteCursor;
    {
        std::lock_guard<std::mutex> lock(paramMutex);
        currentWriteCursor = writeCursor;

        //
        size_t startPos = currentWriteCursor % audioBuffer.size();
        size_t copySize = min(beatLength,
                              static_cast<int>(audioBuffer.size() - startPos));

        std::copy(audioBuffer.begin() + startPos,
                  audioBuffer.begin() + startPos + copySize,
                  buffer);

        if (copySize < beatLength)
        {
            std::copy(audioBuffer.begin(),
                      audioBuffer.begin() + (beatLength - copySize),
                      buffer + copySize);
        }

        writeCursor += beatLength;
    }

    hdr->lpData = reinterpret_cast<char *>(buffer);
    hdr->dwBufferLength = beatLength * sizeof(int16_t);

    //
    MMRESULT result = waveOutPrepareHeader(hWaveOut, hdr, sizeof(WAVEHDR));
    if (result != MMSYSERR_NOERROR)
    {
        delete[] buffer;
        delete hdr;
        return;
    }

    result = waveOutWrite(hWaveOut, hdr, sizeof(WAVEHDR));
    if (result != MMSYSERR_NOERROR)
    {
        waveOutUnprepareHeader(hWaveOut, hdr, sizeof(WAVEHDR));
        delete[] buffer;
        delete hdr;
        return;
    }

    //
    const int beatMs = 60000 / audioBpm;
    auto sleepUntil = std::chrono::steady_clock::now() +
                      std::chrono::milliseconds(beatMs);
    
    // Interruptible sleep
    std::unique_lock<std::mutex> lock(stopMutex);
    stopCV.wait_until(lock, sleepUntil, [this] { return !playing.load(); });
}

void Metronome::StartMetronome()
{
    try
    {
        while (playing.load())
        {
            PlaySound();
        }
    }
    catch (...)
    {
        playing.store(false);
        throw;
    }
}
void Metronome::Destroy()
{
    Stop();
    if (hWaveOut)
    {
        waveOutClose(hWaveOut);
        hWaveOut = nullptr;
    }
}
