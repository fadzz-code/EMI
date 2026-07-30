'use client';

import { useState, useEffect } from 'react';
import { env } from '@/lib/env';

export default function AdminKnowledgePage() {
  const [items, setItems] = useState<any[]>([]);
  const [isUploading, setIsUploading] = useState(false);

  // Fungsi pembantu untuk mengambil token
  const getToken = () => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('emi.auth.token'); 
    }
    return null;
  };

  // Mengambil daftar dokumen
  const fetchKnowledge = async () => {
    const token = getToken();
    if (!token) return;

    try {
      const res = await fetch(`${env.apiBaseUrl}/admin/knowledge`, {
        headers: {
          'Accept': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      const json = await res.json();
      const listData = json.data || json;
      
      if (Array.isArray(listData)) {
        setItems(listData);
      } else {
        setItems([]);
      }
    } catch (error) {
      console.error('Gagal mengambil data', error);
    }
  };

  useEffect(() => {
    fetchKnowledge();
  }, []);

  // FITUR AUTO-REFRESH (Polling)
  useEffect(() => {
    const hasPendingItems = items.some(
      (item) => item.status === 'pending' || item.status === 'processing'
    );
    if (!hasPendingItems) return;

    const interval = setInterval(() => {
      fetchKnowledge();
    }, 3000);

    return () => clearInterval(interval);
  }, [items]);

  // Handler Upload
  const handleUpload = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const token = getToken();
    
    if (!token) {
      alert("Token tidak ditemukan! Anda harus login terlebih dahulu.");
      return;
    }

    setIsUploading(true);
    const formData = new FormData(form);
    
    try {
      const res = await fetch(`${env.apiBaseUrl}/admin/knowledge/upload`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: formData,
      });
      
      const json = await res.json();

      if (res.ok && json.status === 'success') {
        alert('Dokumen berhasil diunggah dan sedang diproses!');
        form.reset(); 
        fetchKnowledge(); 
      } else {
        alert('Gagal: ' + (json.message || 'Terjadi kesalahan pada server'));
      }
    } catch (error) {
      alert('Gagal mengunggah dokumen (Masalah Jaringan/Koneksi).');
    } finally {
      setIsUploading(false);
    }
  };

  // ---> TAMBAHAN: Handler Hapus Dokumen <---
  const handleDelete = async (id: number) => {
    // Meminta konfirmasi admin agar tidak terhapus tidak sengaja
    if (!window.confirm('Apakah Anda yakin ingin menghapus dokumen ini? AI tidak akan bisa lagi membaca referensi dari dokumen ini.')) {
      return;
    }

    const token = getToken();
    if (!token) return;

    try {
      const res = await fetch(`${env.apiBaseUrl}/admin/knowledge/${id}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      
      const json = await res.json();

      if (res.ok && json.status === 'success') {
        alert('Dokumen referensi berhasil dihapus.');
        fetchKnowledge(); // Segera perbarui tabel setelah berhasil dihapus
      } else {
        alert('Gagal menghapus: ' + (json.message || 'Terjadi kesalahan pada server'));
      }
    } catch (error) {
      alert('Gagal menghapus dokumen (Masalah Jaringan/Koneksi).');
      console.error(error);
    }
  };

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Manajemen Dokumen AI</h1>

      {/* Area Upload */}
      <div className="bg-white p-6 rounded-lg shadow mb-8 border border-gray-200">
        <h2 className="text-lg font-semibold mb-4">Unggah Referensi Baru</h2>
        <form onSubmit={handleUpload} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Judul Dokumen</label>
            <input 
              type="text" 
              name="title" 
              required 
              className="mt-1 block w-full border border-gray-300 rounded-md p-2 text-black" 
              placeholder="Contoh: Modul Algoritma Semester 1" 
            />
          </div>
          
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 flex justify-center items-center bg-gray-50 hover:bg-gray-100 transition">
            <input 
              type="file" 
              name="document" 
              accept=".pdf,.docx,.txt" 
              required 
              className="w-full h-full cursor-pointer text-black" 
            />
          </div>
          
          <button 
            type="submit" 
            disabled={isUploading} 
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:bg-gray-400 transition"
          >
            {isUploading ? 'Mengunggah...' : 'Unggah & Proses AI'}
          </button>
        </form>
      </div>

      {/* Tabel Status Ingestion */}
      <div className="bg-white rounded-lg shadow overflow-hidden border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Judul</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipe</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status AI</th>
              {/* Kolom Aksi Tambahan */}
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Aksi</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {items.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-6 py-4 text-center text-gray-500">
                  Belum ada dokumen yang diunggah.
                </td>
              </tr>
            ) : (
              items.map((item: any) => (
                <tr key={item.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{item.title}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="uppercase text-sm bg-gray-100 text-gray-700 px-2 py-1 rounded">{item.source_type}</span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {item.status === 'completed' && <span className="text-green-600 font-semibold text-sm">✅ Tersedia di AI</span>}
                    {item.status === 'processing' && <span className="text-yellow-600 font-semibold text-sm">⏳ Memproses (Embedding)</span>}
                    {item.status === 'pending' && <span className="text-gray-500 font-semibold text-sm">Menunggu</span>}
                    {item.status === 'failed' && <span className="text-red-600 font-semibold text-sm">❌ Gagal</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    {/* Tombol Hapus */}
                    <button 
                      onClick={() => handleDelete(item.id)}
                      className="text-red-600 hover:text-red-800 bg-red-50 hover:bg-red-100 px-3 py-1.5 rounded-md transition"
                    >
                      Hapus
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}