import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { I18nProvider } from "@/lib/i18n/provider";

import { LoginForm } from "./login-form";

const replace = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace, refresh: vi.fn() }),
  useSearchParams: () => new URLSearchParams("next=/accounts"),
}));

afterEach(() => vi.restoreAllMocks());

describe("LoginForm", () => {
  it("renders Arabic labels and signs in through the BFF", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ user: {} }), { status: 200 }));
    render(
      <I18nProvider locale="ar">
        <LoginForm />
      </I18nProvider>,
    );

    const submit = screen.getByRole("button", { name: "تسجيل الدخول" });
    expect(submit).toBeDisabled();

    await userEvent.type(screen.getByLabelText("البريد الإلكتروني"), "sara@example.com");
    await userEvent.type(screen.getByLabelText("كلمة المرور"), "secret123");
    await userEvent.click(submit);

    expect(fetchMock).toHaveBeenCalledWith("/api/auth/login", expect.objectContaining({ method: "POST" }));
    expect(replace).toHaveBeenCalledWith("/accounts");
  });

  it("shows server validation errors", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify({ message: "bad", errors: { email: ["These credentials do not match."] } }), { status: 422 }),
    );
    render(
      <I18nProvider locale="en">
        <LoginForm />
      </I18nProvider>,
    );
    await userEvent.type(screen.getByLabelText("Email"), "sara@example.com");
    await userEvent.type(screen.getByLabelText("Password"), "wrong");
    await userEvent.click(screen.getByRole("button", { name: "Sign in" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("These credentials do not match.");
  });
});
