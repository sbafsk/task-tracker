// Custom delete confirmation modal for Rails 8 + Turbo
import { Turbo } from "@hotwired/turbo-rails"

let currentElement = null;

// Override Turbo's confirm method
Turbo.setConfirmMethod((message, element) => {
  return new Promise((resolve) => {
    const modal = document.getElementById('deleteModal');
    const deleteMessage = document.getElementById('deleteMessage');
    const cancelBtn = document.getElementById('cancelDelete');
    const confirmBtn = document.getElementById('confirmDelete');

    if (!modal || !deleteMessage || !cancelBtn || !confirmBtn) {
      // Fallback to browser confirm if modal elements not found
      resolve(window.confirm(message));
      return;
    }

    currentElement = element;
    deleteMessage.textContent = message;
    modal.classList.remove('hidden');

    // Remove any existing listeners to prevent duplicates
    const newCancelBtn = cancelBtn.cloneNode(true);
    const newConfirmBtn = confirmBtn.cloneNode(true);
    cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);

    // Cancel button
    newCancelBtn.addEventListener('click', () => {
      modal.classList.add('hidden');
      currentElement = null;
      resolve(false);
    });

    // Confirm button
    newConfirmBtn.addEventListener('click', () => {
      modal.classList.add('hidden');
      currentElement = null;
      resolve(true);
    });

    // Close on backdrop click
    const handleBackdropClick = (e) => {
      if (e.target === modal) {
        modal.classList.add('hidden');
        modal.removeEventListener('click', handleBackdropClick);
        currentElement = null;
        resolve(false);
      }
    };
    modal.addEventListener('click', handleBackdropClick);

    // Close on Escape key
    const handleEscape = (e) => {
      if (e.key === 'Escape' && !modal.classList.contains('hidden')) {
        modal.classList.add('hidden');
        document.removeEventListener('keydown', handleEscape);
        currentElement = null;
        resolve(false);
      }
    };
    document.addEventListener('keydown', handleEscape);
  });
});
