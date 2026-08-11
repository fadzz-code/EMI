import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { useAuth } = vi.hoisted(() => ({ useAuth: vi.fn() }));

vi.mock("./auth-provider", () => ({ useAuth }));
vi.mock("./delete-account-form", () => ({ DeleteAccountForm: () => <div>delete-form</div> }));

import { AccountDeletionContent } from "./account-deletion-content";

describe("AccountDeletionContent", () => {
  beforeEach(() => useAuth.mockReset());

  it("shows public explanation and login CTA to guests", () => {
    useAuth.mockReturnValue({ status: "unauthenticated" });

    const html = renderToStaticMarkup(<AccountDeletionContent />);

    expect(html).toContain("Penghapusan Akun EMI");
    expect(html).toContain("Akun dan data pribadi akan dihapus permanen");
    expect(html).toContain("/login?returnTo=%2Faccount-deletion");
    expect(html).not.toContain("delete-form");
  });

  it("shows existing deletion form to authenticated users", () => {
    useAuth.mockReturnValue({ status: "authenticated" });

    const html = renderToStaticMarkup(<AccountDeletionContent />);

    expect(html).toContain("delete-form");
    expect(html).not.toContain("Masuk untuk menghapus akun");
  });
});
