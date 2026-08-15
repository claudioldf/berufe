export function buildWhatsAppUrl(phone: string, message: string) {
  const normalizedPhone = phone.replace(/\D/g, "");
  const recipient = normalizedPhone ? normalizedPhone : "";
  return `https://wa.me/${recipient}?text=${encodeURIComponent(message)}`;
}
