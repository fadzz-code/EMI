"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { authService } from "./auth-service";
import type { AuthUser, LoginPayload, RegisterPayload } from "./auth-types";

const TOKEN_KEY = "emi.auth.token";

type AuthContextValue = {
  token: string | null;
  user: AuthUser | null;
  isBootstrapping: boolean;
  isAuthenticated: boolean;
  login: (payload: LoginPayload) => Promise<AuthUser>;
  logout: () => Promise<void>;
  register: (payload: RegisterPayload) => Promise<void>;
  refreshUser: () => Promise<AuthUser | null>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isBootstrapping, setIsBootstrapping] = useState(true);

  const persistToken = useCallback((nextToken: string | null) => {
    setToken(nextToken);

    if (nextToken) {
      window.localStorage.setItem(TOKEN_KEY, nextToken);
    } else {
      window.localStorage.removeItem(TOKEN_KEY);
    }
  }, []);

  const refreshUser = useCallback(async () => {
    if (!token) {
      setUser(null);
      return null;
    }

    const currentUser = await authService.me(token);
    setUser(currentUser);
    return currentUser;
  }, [token]);

  useEffect(() => {
    queueMicrotask(() => {
      const storedToken = window.localStorage.getItem(TOKEN_KEY);
      if (storedToken) {
        setToken(storedToken);
      } else {
        setIsBootstrapping(false);
      }
    });
  }, []);

  useEffect(() => {
    if (!token) {
      return;
    }

    let isMounted = true;

    authService
      .me(token)
      .then((currentUser) => {
        if (isMounted) {
          setUser(currentUser);
        }
      })
      .catch(() => {
        if (isMounted) {
          persistToken(null);
          setUser(null);
        }
      })
      .finally(() => {
        if (isMounted) {
          setIsBootstrapping(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [persistToken, token]);

  const login = useCallback(
    async (payload: LoginPayload) => {
      const result = await authService.login(payload);
      persistToken(result.token);
      setUser(result.user);
      return result.user;
    },
    [persistToken],
  );

  const logout = useCallback(async () => {
    const activeToken = token;
    persistToken(null);
    setUser(null);

    if (activeToken) {
      await authService.logout(activeToken);
    }
  }, [persistToken, token]);

  const register = useCallback(async (payload: RegisterPayload) => {
    await authService.register(payload);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      token,
      user,
      isBootstrapping,
      isAuthenticated: Boolean(token && user),
      login,
      logout,
      register,
      refreshUser,
    }),
    [isBootstrapping, login, logout, refreshUser, register, token, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth harus dipakai di dalam AuthProvider.");
  }

  return context;
}
