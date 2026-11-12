import { useState, useEffect } from 'react';
import { PageId } from '../../App';

interface AppHeaderProps {
  currentPage: PageId;
  onQuickUpload: () => void;
}

export default function AppHeader({ currentPage, onQuickUpload }: AppHeaderProps) {
  const [hostname, setHostname] = useState<string>('connecting...');
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  const titleMap: Record<PageId, string> = {
    dashboard: 'Tổng Quan',
    'media-library': 'Kho Media',
    'upload-media': 'Tải Lên Media',
    collections: 'Bộ Sưu Tập',
    analytics: 'Thống Kê',
    storage: 'Lưu Trữ & FinOps',
    settings: 'Cài Đặt',
  };

  useEffect(() => {
    fetch('/api/info')
      .then(res => res.json())
      .then(data => setHostname(data.hostname || 'fargate-worker'))
      .catch(() => setHostname('local-worker'));
  }, []);

  const toggleTheme = () => {
    const next = theme === 'light' ? 'dark' : 'light';
    setTheme(next);
    document.documentElement.setAttribute('data-theme', next);
  };

  return (
    <header className="h-16 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 sticky top-0 z-40 px-6 flex items-center justify-between gap-4">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-xs md:text-sm font-semibold text-slate-500">
        <span>Cloud Media Studio</span>
        <span>/</span>
        <span className="text-slate-900 dark:text-white font-bold">{titleMap[currentPage]}</span>
      </div>

      {/* Header Actions */}
      <div className="flex items-center gap-3">
        {/* Host Status Badge */}
        <div className="hidden sm:flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-xs font-mono text-slate-600 dark:text-slate-300">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>Host: <strong className="text-indigo-600 dark:text-indigo-400">{hostname}</strong></span>
        </div>

        {/* Quick Upload Button */}
        <button
          onClick={onQuickUpload}
          className="px-3.5 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-1.5"
        >
          <span>☁️</span>
          <span>Tải Lên</span>
        </button>

        {/* Theme Toggle */}
        <button
          onClick={toggleTheme}
          className="w-9 h-9 rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 flex items-center justify-center hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          title="Đổi giao diện Sáng / Tối"
        >
          {theme === 'light' ? '🌙' : '☀️'}
        </button>
      </div>
    </header>
  );
}

