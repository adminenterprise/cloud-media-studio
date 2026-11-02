import React, { useState } from 'react';
import { INITIAL_MEDIA_ITEMS } from '../services/mockData';
import { MediaItem } from '../types/media';

interface MediaLibraryPageProps {
  onNavigateUpload: () => void;
}

export default function MediaLibraryPage({ onNavigateUpload }: MediaLibraryPageProps) {
  const [items, setItems] = useState<MediaItem[]>(INITIAL_MEDIA_ITEMS);
  const [filter, setFilter] = useState<'all' | 'image' | 'video' | 'WebP' | 'Glacier'>('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [search, setSearch] = useState('');
  const [selectedItem, setSelectedItem] = useState<MediaItem | null>(null);

  const filteredItems = items.filter(item => {
    if (filter === 'image' && !['WEBP', 'PNG', 'JPG', 'JPEG'].includes(item.format.toUpperCase())) return false;
    if (filter === 'video' && item.format.toUpperCase() !== 'MP4') return false;
    if (filter === 'WebP' && item.format.toUpperCase() !== 'WEBP') return false;
    if (filter === 'Glacier' && item.storage_class !== 'Glacier') return false;
    if (search && !item.title.toLowerCase().includes(search.toLowerCase()) && !item.tags.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const handleArchive = (id: number) => {
    setItems(prev => prev.map(item => item.id === id ? { ...item, storage_class: 'Glacier', status: 'ARCHIVED' } : item));
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-white">Kho Tài Nguyên Đa Phương Tiện</h1>
          <p className="text-sm text-slate-500 mt-1">Truy xuất, quản lý và phân loại tài nguyên phân phối tốc độ cao qua CloudFront CDN</p>
        </div>
        <button
          onClick={onNavigateUpload}
          className="self-start sm:self-auto px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-2"
        >
          <span>☁️</span>
          <span>Tải Lên File Mới</span>
        </button>
      </div>

      {/* Filter and Control Bar */}
      <div className="p-3.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-1.5 overflow-x-auto text-xs font-semibold">
          {(['all', 'image', 'video', 'WebP', 'Glacier'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg capitalize transition-colors ${
                filter === f
                  ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-600 dark:text-indigo-400 font-bold border border-indigo-200 dark:border-indigo-800'
                  : 'text-slate-500 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800'
              }`}
            >
              {f === 'all' ? 'Tất cả' : f === 'image' ? 'Hình ảnh' : f === 'video' ? 'Video' : f === 'WebP' ? 'WebP nén' : 'S3 Glacier'}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <input
            type="text"
            placeholder="Tìm theo tên hoặc thẻ tags..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-xs text-slate-800 dark:text-white outline-none focus:border-indigo-600 w-48"
          />

          <div className="flex items-center bg-slate-100 dark:bg-slate-800 p-0.5 rounded-lg border border-slate-200 dark:border-slate-700">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded-md text-xs ${viewMode === 'grid' ? 'bg-white dark:bg-slate-900 shadow-sm' : 'text-slate-500'}`}
              title="Lưới"
            >
              ⊞
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-1.5 rounded-md text-xs ${viewMode === 'list' ? 'bg-white dark:bg-slate-900 shadow-sm' : 'text-slate-500'}`}
              title="Danh sách"
            >
              ☰
            </button>
          </div>
        </div>
      </div>

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {filteredItems.map(item => (
            <div
              key={item.id}
              onClick={() => setSelectedItem(item)}
              className="group rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md hover:border-slate-300 dark:hover:border-slate-700 transition-all overflow-hidden flex flex-col cursor-pointer"
            >
              <div className="h-44 bg-slate-100 dark:bg-slate-800 relative overflow-hidden">
                <img
                  src={item.thumbnail_url}
                  alt={item.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <span className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded bg-slate-900/80 backdrop-blur-sm text-[10px] font-mono font-bold text-white">
                  {item.format}
                </span>
                <span className={`absolute top-2.5 right-2.5 px-2 py-0.5 rounded-full text-[10px] font-bold text-white ${item.storage_class === 'Glacier' ? 'bg-cyan-600' : 'bg-emerald-600'}`}>
                  {item.storage_class === 'Glacier' ? '❄️ Glacier' : '⚡ S3'}
                </span>
              </div>

              <div className="p-3.5 flex-1 flex flex-col justify-between gap-3">
                <div>
                  <h3 className="font-bold text-xs text-slate-900 dark:text-white truncate" title={item.title}>{item.title}</h3>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 mt-1">
                    <span>{item.file_size_mb} MB</span>
                    <span>{item.dimensions || '4K UHD'}</span>
                  </div>
                </div>

                <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between" onClick={e => e.stopPropagation()}>
                  <button 
                    onClick={() => navigator.clipboard.writeText(item.thumbnail_url)}
                    className="text-[11px] font-semibold text-slate-500 hover:text-indigo-600"
                  >
                    Sao chép URL
                  </button>
                  {item.storage_class !== 'Glacier' ? (
                    <button
                      onClick={() => handleArchive(item.id)}
                      className="text-[11px] font-bold text-cyan-600 hover:underline"
                    >
                      ❄️ Lưu Glacier
                    </button>
                  ) : (
                    <span className="text-[11px] font-bold text-cyan-500">✓ Đã tối ưu</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-200 dark:border-slate-800 text-slate-400 font-bold uppercase tracking-wider">
                <th className="pb-3">Tài Nguyên</th>
                <th className="pb-3">Định Dạng</th>
                <th className="pb-3">Dung Lượng</th>
                <th className="pb-3">Độ Phân Giải</th>
                <th className="pb-3">Tầng Lưu Trữ</th>
                <th className="pb-3 text-right">Thao Tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800 font-medium">
              {filteredItems.map(item => (
                <tr key={item.id} onClick={() => setSelectedItem(item)} className="hover:bg-slate-50 dark:hover:bg-slate-800/40 cursor-pointer">
                  <td className="py-3 flex items-center gap-3">
                    <img src={item.thumbnail_url} alt="" className="w-9 h-9 rounded object-cover flex-shrink-0" />
                    <div>
                      <div className="font-bold text-slate-900 dark:text-white">{item.title}</div>
                      <div className="text-[11px] text-slate-400">#{item.id} • {item.author}</div>
                    </div>
                  </td>
                  <td className="py-3 font-bold">{item.format}</td>
                  <td className="py-3">{item.file_size_mb} MB</td>
                  <td className="py-3">{item.dimensions}</td>
                  <td className="py-3">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${item.storage_class === 'Glacier' ? 'bg-cyan-100 dark:bg-cyan-950 text-cyan-600' : 'bg-emerald-100 dark:bg-emerald-950 text-emerald-600'}`}>
                      {item.storage_class === 'Glacier' ? '❄️ Glacier' : '⚡ Standard'}
                    </span>
                  </td>
                  <td className="py-3 text-right" onClick={e => e.stopPropagation()}>
                    <button onClick={() => setSelectedItem(item)} className="px-2.5 py-1 rounded bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 font-semibold text-[11px]">
                      Xem
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Slide-over Drawer */}
      {selectedItem && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex justify-end" onClick={() => setSelectedItem(null)}>
          <div className="w-full max-w-md bg-white dark:bg-slate-900 h-full p-6 shadow-2xl flex flex-col justify-between overflow-y-auto" onClick={e => e.stopPropagation()}>
            <div className="space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
                <h2 className="font-bold text-slate-900 dark:text-white">Chi Tiết Tài Nguyên</h2>
                <button onClick={() => setSelectedItem(null)} className="w-7 h-7 rounded hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500">✕</button>
              </div>

              <div className="h-52 rounded-lg bg-slate-100 dark:bg-slate-800 overflow-hidden">
                <img src={selectedItem.thumbnail_url} alt="" className="w-full h-full object-cover" />
              </div>

              <div>
                <h3 className="font-extrabold text-base text-slate-900 dark:text-white">{selectedItem.title}</h3>
                <p className="text-xs text-slate-500 mt-1">Thẻ: {selectedItem.tags}</p>
              </div>

              <div className="p-3.5 rounded-lg bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-800 space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-slate-500">Mã file:</span>
                  <span className="font-bold">#{selectedItem.id}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Định dạng:</span>
                  <span className="font-bold">{selectedItem.format}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Dung lượng:</span>
                  <span className="font-bold">{selectedItem.file_size_mb} MB</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Độ phân giải:</span>
                  <span className="font-bold">{selectedItem.dimensions}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Tầng lưu trữ:</span>
                  <span className="font-bold text-indigo-600">{selectedItem.storage_class}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Tác giả:</span>
                  <span className="font-bold">{selectedItem.author}</span>
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-200 dark:border-slate-800 flex gap-2">
              <button 
                onClick={() => { navigator.clipboard.writeText(selectedItem.thumbnail_url); alert('Đã sao chép URL'); }}
                className="flex-1 py-2 rounded-lg bg-slate-100 dark:bg-slate-800 font-bold text-xs"
              >
                Sao Chép URL
              </button>
              {selectedItem.storage_class !== 'Glacier' && (
                <button 
                  onClick={() => { handleArchive(selectedItem.id); setSelectedItem(null); }}
                  className="flex-1 py-2 rounded-lg bg-indigo-600 text-white font-bold text-xs"
                >
                  ❄️ Lưu Glacier
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

