"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { CONTROL_PACKET_TYPE, Esp32SerialService, getSerialSupport, PCM_PACKET_TYPE, PTT_PRESSED, PTT_RELEASED } from "./esp32-serial-service";
import { MAX_PCM_BYTES, pcmDurationSeconds, pcmS16leToWav } from "./pcm-wav";

export type Esp32CaptureState = "unsupported" | "disconnected" | "permitted" | "connecting" | "ready" | "recording" | "finalizing" | "captured" | "error";

export function useEsp32SerialCapture() {
  const support = useMemo(() => typeof window === "undefined" ? { supported: false, reason: null } : getSerialSupport(window, navigator), []);
  const [state, setState] = useState<Esp32CaptureState>(support.supported ? "disconnected" : "unsupported");
  const [error, setError] = useState<string | null>(support.reason);
  const [notice, setNotice] = useState<string | null>(null);
  const [capture, setCapture] = useState<{ file: File; url: string; duration: number } | null>(null);
  const serviceRef = useRef(new Esp32SerialService());
  const stateRef = useRef<Esp32CaptureState>(state);
  const captureRef = useRef<{ file: File; url: string; duration: number } | null>(null);
  const chunksRef = useRef<Uint8Array[]>([]);
  const byteLengthRef = useRef(0);
  const busyRef = useRef(false);
  const mountedRef = useRef(true);

  const transition = useCallback((next: Esp32CaptureState) => {
    stateRef.current = next;
    if (mountedRef.current) setState(next);
  }, []);

  const clearPartial = useCallback(() => {
    chunksRef.current = [];
    byteLengthRef.current = 0;
  }, []);

  const finishRecording = useCallback(() => {
    if (busyRef.current || byteLengthRef.current === 0) return;
    busyRef.current = true;
    transition("finalizing");
    try {
      const pcm = new Uint8Array(byteLengthRef.current);
      let offset = 0;
      chunksRef.current.forEach((chunk) => { pcm.set(chunk, offset); offset += chunk.length; });
      const blob = pcmS16leToWav(pcm);
      if (captureRef.current) URL.revokeObjectURL(captureRef.current.url);
      const nextCapture = { file: new File([blob], "speaking-emi.wav", { type: "audio/wav" }), url: URL.createObjectURL(blob), duration: pcmDurationSeconds(pcm.length) };
      captureRef.current = nextCapture;
      if (mountedRef.current) {
        setCapture(nextCapture);
        setError(null);
      }
      transition("captured");
    } catch (caught) {
      if (mountedRef.current) setError(caught instanceof Error ? caught.message : "Rekaman alat tidak valid.");
      transition("error");
    } finally {
      busyRef.current = false;
      clearPartial();
    }
  }, [clearPartial, transition]);

  const handlePacket = useCallback((type: number, payload: Uint8Array) => {
    if (type === CONTROL_PACKET_TYPE && payload.length === 1) {
      if (payload[0] === PTT_PRESSED && stateRef.current !== "recording") {
        clearPartial();
        if (captureRef.current) URL.revokeObjectURL(captureRef.current.url);
        captureRef.current = null;
        if (mountedRef.current) {
          setCapture(null);
          setError(null);
        }
        transition("recording");
      } else if (payload[0] === PTT_RELEASED && stateRef.current === "recording") finishRecording();
      return;
    }
    if (type !== PCM_PACKET_TYPE || stateRef.current !== "recording" || payload.length === 0) return;
    if (byteLengthRef.current + payload.length > MAX_PCM_BYTES) {
      clearPartial();
      if (mountedRef.current) setError("Rekaman melewati batas 30 detik.");
      transition("error");
      return;
    }
    chunksRef.current.push(payload.slice());
    byteLengthRef.current += payload.length;
  }, [clearPartial, finishRecording, transition]);

  const handleEnd = useCallback(() => {
    const interrupted = stateRef.current === "recording" || stateRef.current === "finalizing";
    clearPartial();
    if (interrupted) {
      if (mountedRef.current) setError("Sambungan alat terputus saat merekam. Hubungkan kembali lalu ulangi rekaman.");
      transition("error");
    } else transition("disconnected");
  }, [clearPartial, transition]);

  const connect = useCallback(async (requestNew = false) => {
    if (busyRef.current || stateRef.current === "connecting" || stateRef.current === "recording" || stateRef.current === "finalizing") return;
    busyRef.current = true;
    const previous = stateRef.current;
    transition("connecting");
    if (mountedRef.current) { setError(null); setNotice(null); }
    try {
      const result = await serviceRef.current.connect(requestNew, handlePacket, handleEnd);
      if (!mountedRef.current) return;
      if (result.status === "cancelled") {
        setNotice(result.message);
        transition(previous === "permitted" || serviceRef.current.hasPermission ? "permitted" : "disconnected");
      } else transition(result.status === "connected" ? "ready" : serviceRef.current.hasPermission ? "permitted" : "disconnected");
    } catch (caught) {
      if (mountedRef.current) setError(caught instanceof Error ? caught.message : "Gagal menghubungkan alat.");
      transition("error");
    } finally {
      busyRef.current = false;
    }
  }, [handleEnd, handlePacket, transition]);

  const disconnect = useCallback(async () => {
    await serviceRef.current.disconnect();
    clearPartial();
    transition("disconnected");
  }, [clearPartial, transition]);

  useEffect(() => {
    const service = serviceRef.current;
    mountedRef.current = true;
    const reconnect = window.setTimeout(async () => {
      if (!support.supported) return;
      try {
        const result = await service.reconnect(handlePacket, handleEnd);
        transition(result.status === "connected" ? "ready" : service.hasPermission ? "permitted" : "disconnected");
      } catch (caught) {
        if (mountedRef.current) setError(caught instanceof Error ? caught.message : "Gagal menghubungkan alat.");
        transition("error");
      }
    }, 0);
    return () => {
      mountedRef.current = false;
      window.clearTimeout(reconnect);
      void service.dispose();
      clearPartial();
      if (captureRef.current) URL.revokeObjectURL(captureRef.current.url);
      captureRef.current = null;
    };
  }, [clearPartial, handleEnd, handlePacket, support.supported, transition]);

  return { supported: support.supported, state, error, notice, capture, connect, disconnect, stopPlayback: () => serviceRef.current.stopPlayback() };
}
