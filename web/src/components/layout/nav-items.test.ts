import { describe, expect, it } from "vitest";

import { visibleNavItems } from "./nav-items";

describe("visibleNavItems", () => {
  it("hides the admin area from regular users", () => {
    expect(visibleNavItems("user").map((i) => i.href)).not.toContain("/admin");
    expect(visibleNavItems(undefined).map((i) => i.href)).not.toContain("/admin");
  });

  it("shows the admin area to admins", () => {
    expect(visibleNavItems("admin").map((i) => i.href)).toContain("/admin");
  });
});
