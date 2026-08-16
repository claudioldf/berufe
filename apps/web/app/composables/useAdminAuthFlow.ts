import { shallowRef } from "vue";
import {
  createAdminSession,
  type CreateAdminSessionInput,
} from "~/services/api/admin-session";
import { useApiClient } from "~/services/api/client";
import { ApiRequestError } from "~/services/api/errors";

interface AdminAuthFlowDependencies {
  authenticate?: (input: CreateAdminSessionInput) => Promise<void>;
}

export function useAdminAuthFlow(dependencies: AdminAuthFlowDependencies = {}) {
  const email = shallowRef("");
  const password = shallowRef("");
  const isLoading = shallowRef(false);
  const error = shallowRef("");
  const authenticate =
    dependencies.authenticate ??
    ((input: CreateAdminSessionInput) =>
      createAdminSession(useApiClient(), input));

  async function login(): Promise<boolean> {
    if (isLoading.value) return false;

    error.value = "";
    if (!email.value.trim() || !password.value) {
      error.value = "Informe seu e-mail e sua senha.";
      return false;
    }

    isLoading.value = true;
    try {
      await authenticate({
        email: email.value.trim(),
        password: password.value,
      });
      password.value = "";
      return true;
    } catch (loginError) {
      error.value =
        loginError instanceof ApiRequestError
          ? loginError.message
          : "Não foi possível entrar agora. Tente novamente em instantes.";
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  return {
    email,
    password,
    isLoading,
    error,
    login,
  };
}
