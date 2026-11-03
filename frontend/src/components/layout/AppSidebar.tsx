import React from 'react';
import { PageId } from '../../App';
import { INITIAL_USER } from '../../services/mockData';

interface AppSidebarProps {
  currentPage: PageId;
  onNavigate: (page: PageId) => void;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export default function AppSidebar({ currentPage, onNavigate, isCollapsed, onToggleCollapse }: AppSidebarProps) {
  const navItems: { id: PageId; label: string; icon: string; badge?: string }[] = [
    { id: 'dashboard', label: 'Tổng Quan', icon: '📊' },
    { id: 'media-library', label: 'Kho Media', icon: '📁', badge: '6' },
    { id: 'upload-media', label: 'Tải Lên Media', icon: '☁️' },
    { id: 'collections', label: 'Bộ Sưu Tập', icon: '🗂️' },
    { id: 'analytics', label: 'Thống Kê', icon: '📈' },
    { id: 'storage', label: 'Lưu Trữ & FinOps', icon: '❄️', badge: '84%' },
    { id: 'settings', label: 'Cài Đặt', icon: '⚙️' },
  ];

  return (
    <aside className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col bg-slate-900 border-r border-slate-800 transition-all duration-200 ${isCollapsed ? 'w-[72px]' : 'w-[260px]'}`}>
      {/* Brand Header */}
      <div className="h-16 flex items-center justify-between px-4 border-b border-slate-800">
        <div className="flex items-center gap-3 overflow-hidden cursor-pointer" onClick={() => onNavigate('dashboard')}>
          <div className="w-9 h-9 rounded-lg bg-gradient-to-tr from-indigo-600 to-cyan-500 flex items-center justify-center text-white text-lg font-bold shadow-md shadow-indigo-600/30 flex-shrink-0">
            🎬
          </div>
          {!isCollapsed && (
            <div className="flex flex-col">
              <span className="font-extrabold text-white tracking-tight leading-tight">Cloud Media</span>
              <span className="text-[10px] font-bold text-cyan-400 uppercase tracking-wider">Enterprise SaaS</span>
            </div>
          )}
        </div>
        <button 
          onClick={onToggleCollapse}
          className="w-7 h-7 rounded flex items-center justify-center text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          title={isCollapsed ? 'Mở rộng' : 'Thu gọn'}
        >
          {isCollapsed ? '▶' : '◀'}
        </button>
      </div>

      {/* Nav List */}
      <nav className="flex-1 px-2.5 py-4 space-y-1 overflow-y-auto">
        {!isCollapsed && (
          <div className="px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider text-slate-500">
            Quản Lý & Phân Phối
          </div>
        )}
        {navItems.map((item) => {
          const isActive = currentPage === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-all text-left ${
                isActive
                  ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-slate-100 hover:bg-slate-800/80'
              }`}
            >
              <span className="text-base flex-shrink-0">{item.icon}</span>
              {!isCollapsed && <span className="flex-1 truncate">{item.label}</span>}
              {!isCollapsed && item.badge && (
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/10 text-white">
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Footer User */}
      <div className="p-3 border-t border-slate-800 bg-black/20">
        <div className="flex items-center gap-3">
          <img 
            src={INITIAL_USER.avatarUrl} 
            alt="Avatar" 
            className="w-9 h-9 rounded-full object-cover border border-slate-700 flex-shrink-0"
          />
          {!isCollapsed && (
            <div className="truncate">
              <div className="text-xs font-bold text-slate-200 truncate">{INITIAL_USER.name}</div>
              <div className="text-[11px] text-slate-400 truncate">{INITIAL_USER.role}</div>
            </div>
          )}
        </div>
      </div>
    </aside>
  );
}

