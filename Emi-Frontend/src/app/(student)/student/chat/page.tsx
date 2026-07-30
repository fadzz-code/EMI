'use client';

import { useState, useEffect } from 'react';
import { env } from '@/lib/env';

type Message = {
  role: 'user' | 'ai';
  content: string;
  source?: 'local_document' | 'google_search_internet';
};

type ChatSession = {
  id: string;
  title: string;
  date: string;
  messages: Message[];
};

export default function StudentChatPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const [sessionId, setSessionId] = useState(''); 
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [chatHistory, setChatHistory] = useState<ChatSession[]>([]);

  useEffect(() => {
    setSessionId(Date.now().toString());
    const savedHistory = localStorage.getItem('emi.chat.history');
    if (savedHistory) {
      setChatHistory(JSON.parse(savedHistory));
    }
  }, []);

  const getToken = () => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('emi.auth.token');
    }
    return null;
  };

  // ---> FUNGSI BARU: Logika Cerdas Menyimpan Sesi <---
  const saveCurrentSession = () => {
    if (messages.length === 0) return; // Jangan simpan jika kosong

    const firstUserMsg = messages.find(m => m.role === 'user')?.content || 'Sesi Obrolan';
    const title = firstUserMsg.length > 30 ? firstUserMsg.substring(0, 30) + '...' : firstUserMsg;

    const currentSessionItem: ChatSession = {
      id: sessionId,
      title: title,
      date: new Date().toLocaleString('id-ID', { dateStyle: 'short', timeStyle: 'short' }),
      messages: [...messages]
    };

    setChatHistory(prevHistory => {
      // Cari apakah sesi ini sudah ada di dalam array riwayat
      const existingIndex = prevHistory.findIndex(s => s.id === sessionId);
      let updatedHistory;

      if (existingIndex >= 0) {
        // Jika SUDAH ADA, perbarui data (tindih) sesi tersebut
        updatedHistory = [...prevHistory];
        updatedHistory[existingIndex] = currentSessionItem;
      } else {
        // Jika BELUM ADA, tambahkan di posisi paling atas
        updatedHistory = [currentSessionItem, ...prevHistory];
      }

      localStorage.setItem('emi.chat.history', JSON.stringify(updatedHistory));
      return updatedHistory;
    });
  };

  // Fungsi membuat obrolan baru
  const startNewSession = () => {
    saveCurrentSession(); // Simpan atau perbarui sesi yang sedang aktif
    setMessages([]); // Kosongkan layar
    setSessionId(Date.now().toString()); // Buat ID baru
    setIsHistoryOpen(false); 
  };

  // Fungsi memuat riwayat lama
  const loadSession = (session: ChatSession) => {
    if (sessionId !== session.id) {
       saveCurrentSession(); // Simpan obrolan saat ini sebelum pindah
    }
    setSessionId(session.id);
    setMessages(session.messages);
    setIsHistoryOpen(false);
  };

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMsg = input;
    setMessages((prev) => [...prev, { role: 'user', content: userMsg }]);
    setInput('');
    setIsLoading(true);

    const token = getToken();

    if (!token) {
      setMessages((prev) => [
        ...prev, 
        { role: 'ai', content: 'Maaf, token tidak ditemukan. Anda harus login terlebih dahulu.' }
      ]);
      setIsLoading(false);
      return;
    }

    try {
      const res = await fetch(`${env.apiBaseUrl}/student/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ prompt: userMsg, session_id: sessionId }),
      });
      
      const json = await res.json();
      
      if (res.ok && json.status === 'success') {
        setMessages((prev) => [
          ...prev, 
          { 
            role: 'ai', 
            content: json.data.ai_response, 
            source: json.data.source_used 
          }
        ]);
      } else {
        setMessages((prev) => [
          ...prev, 
          { role: 'ai', content: `Maaf, terjadi kesalahan: ${json.message || 'Respons server tidak valid.'}` }
        ]);
      }
    } catch (error) {
      setMessages((prev) => [...prev, { role: 'ai', content: 'Maaf, terjadi kesalahan jaringan.' }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gray-50 max-w-4xl mx-auto border-x border-gray-200 relative overflow-hidden">
      
      {/* Header */}
      <div className="bg-white border-b border-gray-200 p-4 flex justify-between items-center z-10">
        <div>
          <h1 className="text-xl font-bold text-gray-800">EMI Bot</h1>
          <p className="text-sm text-gray-500">Tanya seputar materi kuliah atau pengetahuan umum.</p>
        </div>
        
        <div className="flex gap-2">
          <button 
            onClick={() => setIsHistoryOpen(true)}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition flex items-center gap-2"
          >
            🕒 Riwayat
          </button>
          <button 
            onClick={startNewSession}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md transition flex items-center gap-2"
          >
            + Sesi Baru
          </button>
        </div>
      </div>

      {/* Area Chat Utama */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        {messages.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-gray-400">
            <span className="text-4xl mb-3">👋</span>
            <p>Halo! Ada yang bisa EMI bantu hari ini?</p>
          </div>
        )}

        {messages.map((msg, idx) => (
          <div key={idx} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] rounded-2xl p-4 ${msg.role === 'user' ? 'bg-blue-600 text-white' : 'bg-white border border-gray-200 text-black shadow-sm'}`}>
              <div className="whitespace-pre-wrap leading-relaxed">{msg.content}</div>
              
              {msg.role === 'ai' && msg.source && (
                <div className="mt-3 border-t pt-2">
                  {msg.source === 'local_document' ? (
                    <span className="inline-flex items-center text-xs font-medium text-green-700 bg-green-50 px-2 py-1 rounded-full ring-1 ring-inset ring-green-600/20">
                      💡 Bersumber dari Dokumen Kampus
                    </span>
                  ) : (
                    <span className="inline-flex items-center text-xs font-medium text-blue-700 bg-blue-50 px-2 py-1 rounded-full ring-1 ring-inset ring-blue-700/10">
                      🌐 Pengetahuan Umum
                    </span>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-white border border-gray-200 shadow-sm rounded-2xl p-4 animate-pulse text-gray-400">
              EMI sedang berpikir...
            </div>
          </div>
        )}
      </div>

      {/* Area Input Box */}
      <div className="p-4 bg-white border-t border-gray-200 z-10">
        <form onSubmit={sendMessage} className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Tanyakan sesuatu pada EMI..."
            className="flex-1 border border-gray-300 rounded-full px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 text-black"
            disabled={isLoading}
          />
          <button 
            type="submit" 
            disabled={isLoading || !input.trim()}
            className="bg-blue-600 text-white p-2 rounded-full w-10 h-10 flex items-center justify-center hover:bg-blue-700 disabled:bg-gray-400 transition"
          >
            ➤
          </button>
        </form>
      </div>

      {/* Sidebar Riwayat (Overlay) */}
      {isHistoryOpen && (
        <div className="absolute top-0 right-0 w-80 h-full bg-white shadow-2xl border-l border-gray-200 z-50 flex flex-col transform transition-transform duration-300">
          <div className="p-4 border-b border-gray-200 flex justify-between items-center bg-gray-50">
            <h2 className="font-bold text-gray-800">Riwayat Percakapan</h2>
            <button 
              onClick={() => setIsHistoryOpen(false)}
              className="text-gray-500 hover:text-red-500 font-bold text-xl"
            >
              ✕
            </button>
          </div>
          <div className="p-2 flex-1 overflow-y-auto space-y-2">
            {chatHistory.length === 0 ? (
              <div className="text-center text-sm text-gray-500 mt-10">
                <p>Belum ada riwayat percakapan.</p>
                <p className="mt-2 text-xs">Mulai chat dan tekan "Sesi Baru" untuk menyimpannya di sini.</p>
              </div>
            ) : (
              chatHistory.map((session) => (
                <div 
                  key={session.id}
                  onClick={() => loadSession(session)}
                  className={`p-3 rounded-lg cursor-pointer border transition-colors ${
                    sessionId === session.id 
                      ? 'border-blue-500 bg-blue-50' 
                      : 'border-gray-200 hover:bg-gray-100 bg-white'
                  }`}
                >
                  <p className="font-semibold text-sm text-gray-800 truncate">{session.title}</p>
                  <div className="flex justify-between items-center mt-1">
                    <span className="text-xs text-gray-500">{session.date}</span>
                    <span className="text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full">
                      {session.messages.length} pesan
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
      
      {/* Background redup ketika sidebar terbuka */}
      {isHistoryOpen && (
        <div 
          onClick={() => setIsHistoryOpen(false)}
          className="absolute inset-0 bg-black/20 z-40"
        />
      )}
    </div>
  );
}