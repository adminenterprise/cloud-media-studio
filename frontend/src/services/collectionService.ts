import { Collection } from '../types/collection';
import { INITIAL_COLLECTIONS } from './mockData';

let collectionsStore: Collection[] = [...INITIAL_COLLECTIONS];

export const collectionService = {
  async getAll(): Promise<Collection[]> {
    return Promise.resolve([...collectionsStore]);
  },

  async create(payload: { name: string; description: string; colorTag?: string }): Promise<Collection> {
    const newCol: Collection = {
      id: `col-${Date.now().toString(36)}`,
      name: payload.name,
      description: payload.description,
      itemCount: 0,
      totalSizeMb: 0,
      colorTag: payload.colorTag || '#4f46e5',
      coverThumbnails: [
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200&auto=format&fit=crop&q=80'
      ],
      createdAt: new Date().toISOString().split('T')[0],
      updatedAt: new Date().toISOString().split('T')[0],
      createdBy: 'Alex Morgan'
    };
    collectionsStore.unshift(newCol);
    return Promise.resolve(newCol);
  },

  async delete(id: string): Promise<boolean> {
    collectionsStore = collectionsStore.filter(c => c.id !== id);
    return Promise.resolve(true);
  }
};

