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

type AuthStatus = "loading" | "authenticated" | "unauthenticated";

type AuthContextValue = {
  token: string | null;
  user: AuthUser | null;
  status: AuthStatus;
  isBootstrapping: boolean;
  isAuthenticated: boolean;
  login: (payload: LoginPayload) => Promise<AuthUser>;
  logout: () => Promise<void>;
  registerTeacher: (
    payload: Omit<RegisterPayload, "requested_role">,
  ) => Promise<void>;
  registerStudent: (
    payload: Omit<RegisterPayload, "requested_role">,
  ) => Promise<void>;
  refreshUser: () => Promise<AuthUser | null>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [status, setStatus] = useState<AuthStatus>("loading");

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
      setStatus("unauthenticated");
      return null;
    }

    const currentUser = await authService.getCurrentUser(token);
    setUser(currentUser);
    setStatus("authenticated");
    return currentUser;
  }, [token]);

  useEffect(() => {
    queueMicrotask(() => {
      const storedToken = window.localStorage.getItem(TOKEN_KEY);
      if (storedToken) {
        setToken(storedToken);
      } else {
        setStatus("unauthenticated");
      }
    });
  }, []);

  useEffect(() => {
    if (!token) {
      return;
    }

    let isMounted = true;

    authService
      .getCurrentUser(token)
      .then((currentUser) => {
        if (isMounted) {
          setUser(currentUser);
          setStatus("authenticated");
        }
      })
      .catch(() => {
        if (isMounted) {
          persistToken(null);
          setUser(null);
          setStatus("unauthenticated");
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
      setStatus("authenticated");
      return result.user;
    },
    [persistToken],
  );

  const logout = useCallback(async () => {
    const activeToken = token;
    persistToken(null);
    setUser(null);
    setStatus("unauthenticated");

    if (activeToken) {
      try {
        await authService.logout(activeToken);
      } catch {
        // Token lokal tetap dibersihkan meski server sudah menganggap sesi tidak valid.
      }
    }
  }, [persistToken, token]);

  const registerTeacher = useCallback(
    async (payload: Omit<RegisterPayload, "requested_role">) => {
      await authService.registerTeacher(payload);
    },
    [],
  );

  const registerStudent = useCallback(
    async (payload: Omit<RegisterPayload, "requested_role">) => {
      await authService.registerStudent(payload);
    },
    [],
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      token,
      user,
      status,
      isBootstrapping: status === "loading",
      isAuthenticated: status === "authenticated" && Boolean(token && user),
      login,
      logout,
      registerTeacher,
      registerStudent,
      refreshUser,
    }),
    [
      login,
      logout,
      refreshUser,
      registerStudent,
      registerTeacher,
      status,
      token,
      user,
    ],
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
