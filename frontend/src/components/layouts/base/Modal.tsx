import { stateModal } from "../../../states/display";
import Test from "./Test";

export default function Modal() {
  // const modalStore = useModalStore();

  return (
    <>
      {stateModal.visible && (
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" />
          <div class="relative z-10 w-full max-w-md rounded-xl bg-white p-6 shadow-2xl">
            <button
              class="absolute top-1 right-1 h-8 w-8 rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-700"
              type="button"
              aria-label="Close modal"
              onClick={() => stateModal.visible = false}
            >
              ✕
            </button>
            <div class="mt-2">{stateModal.content}</div>
          </div>
        </div>
      )}

      <button
        class="rounded-lg bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700"
        type="button"
        onClick={() => {
          stateModal.visible = true;
          stateModal.content = <Test id={1} />;
        }}
      >
        SHOW MODAL
      </button>
    </>
  );
}
