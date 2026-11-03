/**
 * API Client abstraction
 * Sử dụng VITE_API_BASE_URL hoặc mặc định window.location.origin
 */
const BASE_URL = import.meta.env?.VITE_API_BASE_URL || '';

export async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };

  const response = await fetch(url, {
    ...options,
    headers
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
  }

  return response.json() as Promise<T>;
}

