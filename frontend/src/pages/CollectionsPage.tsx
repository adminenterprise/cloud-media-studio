import React, { useState, useEffect } from 'react';
import { 
  FolderPlus, 
  Folder, 
  MoreVertical, 
  ExternalLink, 
  Trash2, 
  Layers, 
  Calendar, 
  HardDrive,
  Search,
  CheckCircle2,
  X
} from 'lucide-react';
import { Collection } from '../types/collection';
import { collectionService } from '../services/collectionService';

interface CollectionsPageProps {
  onOpenCollection: (collectionId: string) => void;
}

export default function CollectionsPage({ onOpenCollection }: CollectionsPageProps) {
  const [collections, setCollections] = useState<Collection[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newColName, setNewColName] = useState('');
  const [newColDesc, setNewColDesc] = useState('');
  const [newColColor, setNewColColor] = useState('#4f46e5');
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  useEffect(() => {
    loadCollections();
  }, []);

  const loadCollections = async () => {
    setLoading(true);
    const data = await collectionService.getAll();
    setCollections(data);
    setLoading(false);
  };

  const handleCreateCollection = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newColName.trim()) return;

    await collectionService.create({
      name: newColName.trim(),
      description: newColDesc.trim() || 'Custom media collection for enterprise campaigns',
      colorTag: newColColor
    });

    setNewColName('');
    setNewColDesc('');
    setShowCreateModal(false);
    setActionNotice('Collection created successfully');
    setTimeout(() => setActionNotice(null), 3000);
    loadCollections();
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Delete collection "${name}"? Files will remain in Media Library.`)) return;
    await collectionService.delete(id);
    setActionNotice(`Collection "${name}" removed`);
    setTimeout(() => setActionNotice(null), 3000);
    loadCollections();
  };

  const filteredCollections = collections.filter(c => 
    c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Top Banner & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Collections</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Organize assets into campaign folders and team workspaces (Canva & Google Drive inspired).
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium rounded-lg text-white bg-indigo-600 hover:bg-indigo-700 shadow-sm transition-colors"
        >
          <FolderPlus className="w-4 h-4" />
          <span>New Collection</span>
        </button>
      </div>

      {actionNotice && (
        <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 rounded-lg flex items-center gap-2 text-sm text-emerald-800 dark:text-emerald-300">
          <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
          <span>{actionNotice}</span>
        </div>
      )}

      {/* Filter / Search Bar */}
      <div className="flex items-center justify-between gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search collections by name or description..."
            className="w-full pl-9 pr-4 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
        <div className="text-sm text-slate-500 dark:text-slate-400 font-medium">
          {filteredCollections.length} {filteredCollections.length === 1 ? 'collection' : 'collections'}
        </div>
      </div>

      {/* Collection Grid */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse">
          {[1, 2, 3].map(n => (
            <div key={n} className="h-64 bg-slate-200 dark:bg-slate-800 rounded-xl" />
          ))}
        </div>
      ) : filteredCollections.length === 0 ? (
        <div className="text-center py-16 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-8">
          <Folder className="w-12 h-12 text-slate-300 dark:text-slate-600 mx-auto mb-3" />
          <h3 className="text-base font-semibold text-slate-800 dark:text-slate-200">No collections found</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-sm mx-auto mt-1 mb-4">
            Create your first collection to group campaign media, social assets, or client deliverables.
          </p>
          <button
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg text-white bg-indigo-600 hover:bg-indigo-700 transition"
          >
            <FolderPlus className="w-4 h-4" />
            Create Collection
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredCollections.map((col) => (
            <div
              key={col.id}
              className="group bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-sm hover:shadow-md hover:border-indigo-300 dark:hover:border-indigo-700 transition overflow-hidden flex flex-col"
            >
              {/* Cover Collage Thumbnail */}
              <div 
                onClick={() => onOpenCollection(col.id)}
                className="h-36 bg-slate-100 dark:bg-slate-800 relative cursor-pointer overflow-hidden"
              >
                {col.coverThumbnails && col.coverThumbnails.length > 0 ? (
                  <div className="grid grid-cols-3 h-full gap-0.5">
                    {col.coverThumbnails.slice(0, 3).map((thumb, idx) => (
                      <img
                        key={idx}
                        src={thumb}
                        alt=""
                        className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                    ))}
                  </div>
                ) : (
                  <div className="flex items-center justify-center h-full text-slate-400">
                    <Layers className="w-8 h-8 opacity-40" />
                  </div>
                )}
                <div 
                  className="absolute top-3 left-3 w-3 h-3 rounded-full ring-2 ring-white dark:ring-slate-900"
                  style={{ backgroundColor: col.colorTag || '#4f46e5' }}
                />
              </div>

              {/* Card Body */}
              <div className="p-5 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <h3 
                      onClick={() => onOpenCollection(col.id)}
                      className="font-semibold text-slate-900 dark:text-white text-base hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer line-clamp-1"
                    >
                      {col.name}
                    </h3>
                    <button
                      onClick={() => handleDelete(col.id, col.name)}
                      title="Delete Collection"
                      className="text-slate-400 hover:text-rose-600 dark:hover:text-rose-400 p-1 rounded transition"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 line-clamp-2">
                    {col.description}
                  </p>
                </div>

                {/* Footer Metadata */}
                <div className="pt-4 mt-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                  <div className="flex items-center gap-1.5">
                    <Layers className="w-3.5 h-3.5" />
                    <span>{col.itemCount} items</span>
                    <span className="text-slate-300 dark:text-slate-700">•</span>
                    <HardDrive className="w-3.5 h-3.5" />
                    <span>{col.totalSizeMb.toFixed(1)} MB</span>
                  </div>
                  <button
                    onClick={() => onOpenCollection(col.id)}
                    className="inline-flex items-center gap-1 text-indigo-600 dark:text-indigo-400 font-medium hover:underline"
                  >
                    <span>View</span>
                    <ExternalLink className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Collection Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-2xl max-w-md w-full p-6 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <FolderPlus className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                <h3 className="font-semibold text-slate-900 dark:text-white">Create New Collection</h3>
              </div>
              <button 
                onClick={() => setShowCreateModal(false)}
                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateCollection} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Collection Name *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g., Summer Campaign 2026"
                  value={newColName}
                  onChange={(e) => setNewColName(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Description
                </label>
                <textarea
                  rows={2}
                  placeholder="Purpose of this media collection..."
                  value={newColDesc}
                  onChange={(e) => setNewColDesc(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Color Tag
                </label>
                <div className="flex items-center gap-3">
                  {['#4f46e5', '#06b6d4', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6'].map(color => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setNewColColor(color)}
                      className={`w-6 h-6 rounded-full transition-transform ${newColColor === color ? 'ring-2 ring-offset-2 ring-indigo-600 scale-110' : 'opacity-80 hover:opacity-100'}`}
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-medium rounded-lg text-white bg-indigo-600 hover:bg-indigo-700 transition"
                >
                  Create Collection
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
