import { test as setup } from "@playwright/test";

import { loginThroughUi, type Role } from "../../playwright/helpers/auth";

const roles: Role[] = ["admin", "teacher", "student"];

for (const role of roles) {
  setup(`autentikasi ${role}`, async ({ page }) => {
    await loginThroughUi(page, role);
    await page.context().storageState({ path: `playwright/.auth/${role}.json` });
  });
}
