import { readonly } from "vue";
import type { AppRole } from "~/types";

export function useAppRole() {
  const role = useState<AppRole>("app-role", () => "visitor");

  function setRole(nextRole: AppRole) {
    role.value = nextRole;
  }

  return {
    role: readonly(role),
    setRole,
  };
}
