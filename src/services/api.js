import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api',
  timeout: 10000,
});

const TOKEN_KEY = 'portal_access_token';

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const saveToken = (token) => {
  localStorage.setItem(TOKEN_KEY, token);
};

export const clearToken = () => {
  localStorage.removeItem(TOKEN_KEY);
};

export const getToken = () => localStorage.getItem(TOKEN_KEY);

export const login = async (email, password) => {
  const { data } = await api.post('/auth/login', { email, password });
  saveToken(data.accessToken);
  return data;
};

export const register = async ({ name, email, password }) => {
  const { data } = await api.post('/auth/register', { name, email, password });
  saveToken(data.accessToken);
  return data;
};

export const getMe = async () => {
  const { data } = await api.get('/auth/me');
  return data;
};

export const getAdminDashboard = async () => {
  const { data } = await api.get('/admin/dashboard');
  return data;
};

export const getRecentTransactions = async (limit = 5) => {
  const { data } = await api.get('/trades/recent', { params: { limit } });
  return data;
};

export const getBusinesses = async () => {
  const { data } = await api.get('/businesses');
  return data;
};

export default api;
