import { onScopeDispose, readonly, shallowRef } from "vue";

export function useImagePreview() {
  const previewUrl = shallowRef("");

  function clearPreview() {
    if (previewUrl.value) URL.revokeObjectURL(previewUrl.value);
    previewUrl.value = "";
  }

  function setPreviewFile(file: File | null) {
    clearPreview();
    if (!file) return;

    try {
      previewUrl.value = URL.createObjectURL(file);
    } catch {
      previewUrl.value = "";
    }
  }

  onScopeDispose(clearPreview);

  return {
    previewUrl: readonly(previewUrl),
    setPreviewFile,
    clearPreview,
  };
}
