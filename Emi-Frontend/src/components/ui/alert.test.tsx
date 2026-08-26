import { act } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, describe, expect, it, vi } from "vitest";

import { MutationAlert } from "./alert";

const roots: Array<ReturnType<typeof createRoot>> = [];

afterEach(() => {
  roots.splice(0).forEach((root) => act(() => root.unmount()));
  document.body.innerHTML = "";
  vi.restoreAllMocks();
});

function renderAlert(eventKey: unknown, tone: "error" | "success" = "error") {
  const container = document.createElement("div");
  document.body.append(container);
  const root = createRoot(container);
  roots.push(root);
  act(() => root.render(<MutationAlert eventKey={eventKey} tone={tone}>Saved</MutationAlert>));
  return { container, root };
}

describe("MutationAlert", () => {
  it("uses assertive alert semantics for errors and polite status semantics otherwise", () => {
    vi.stubGlobal("matchMedia", vi.fn(() => ({ matches: false })));
    HTMLElement.prototype.scrollIntoView = vi.fn();
    const error = renderAlert(1).container.firstElementChild;
    const success = renderAlert(1, "success").container.firstElementChild;
    expect(error?.getAttribute("role")).toBe("alert");
    expect(error?.getAttribute("aria-live")).toBe("assertive");
    expect(error?.getAttribute("aria-atomic")).toBe("true");
    expect(success?.getAttribute("role")).toBe("status");
    expect(success?.getAttribute("aria-live")).toBe("polite");
  });

  it("focuses and scrolls only when eventKey changes", () => {
    vi.stubGlobal("matchMedia", vi.fn(() => ({ matches: false })));
    const focus = vi.spyOn(HTMLElement.prototype, "focus");
    const scrollIntoView = vi.fn();
    HTMLElement.prototype.scrollIntoView = scrollIntoView;
    const { root } = renderAlert(1);
    expect(focus).toHaveBeenCalledTimes(1);
    expect(scrollIntoView).toHaveBeenCalledWith({ behavior: "smooth", block: "center" });
    act(() => root.render(<MutationAlert eventKey={1} tone="error">Retry</MutationAlert>));
    expect(focus).toHaveBeenCalledTimes(1);
    act(() => root.render(<MutationAlert eventKey={2} tone="error">Retry</MutationAlert>));
    expect(focus).toHaveBeenCalledTimes(2);
    expect(scrollIntoView).toHaveBeenCalledTimes(2);
  });

  it("uses automatic scrolling for reduced motion", () => {
    vi.stubGlobal("matchMedia", vi.fn(() => ({ matches: true })));
    const scrollIntoView = vi.fn();
    HTMLElement.prototype.scrollIntoView = scrollIntoView;
    renderAlert(1, "success");
    expect(scrollIntoView).toHaveBeenCalledWith({ behavior: "auto", block: "center" });
  });
});
