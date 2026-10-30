import { useModalStore } from "../../../stores/display";
import Test from "./Test";

export default function Modal() {
  const modalStore = useModalStore();

  return (
    <>
      {modalStore.visible.value && (
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" />
          <div class="relative z-10 w-full max-w-md rounded-xl bg-white p-6 shadow-2xl">
            <button
              class="absolute top-1 right-1 h-8 w-8 rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-700"
              type="button"
              aria-label="Close modal"
              onClick={modalStore.closeModal}
            >
              ✕
            </button>
            <div class="mt-2">{modalStore.content.value}</div>
          </div>
        </div>
      )}

      <button
        class="rounded-lg bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700"
        type="button"
        onClick={() => modalStore.openModal(<Test id={1} />)}
      >
        SHOW MODAL
      </button>
    </>
  );
}
