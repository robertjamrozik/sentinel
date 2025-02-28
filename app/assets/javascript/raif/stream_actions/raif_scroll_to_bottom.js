import { Turbo } from "@hotwired/turbo-rails";

Turbo.StreamActions.sentinel_scroll_to_bottom = function () {
  const targetSelector = this.getAttribute("target");
  const targetElement = document.getElementById(targetSelector);

  if (targetElement) {
    targetElement.scrollTo({ top: targetElement.scrollHeight, behavior: "smooth" });
  } else {
    console.warn(`scrollToBottom: No element found for selector '${targetSelector}'`);
  }
};