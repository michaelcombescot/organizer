interface TestProps {
  id: number;
}

export default function Test({ id }: TestProps) {
  return <div>Test Component {id}</div>;
}
