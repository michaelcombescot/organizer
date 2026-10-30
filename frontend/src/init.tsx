import { render } from "preact";
import App from "./App";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import "dayjs/locale/fr";
import "./css/main.css";

dayjs.locale(navigator.language || navigator.languages[0] || "en");
dayjs.extend(relativeTime);

const root = document.getElementById("app");
if (!root) {
  throw new Error('Missing application root element "#app".');
}

render(<App />, root);
