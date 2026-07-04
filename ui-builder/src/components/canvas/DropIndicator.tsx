import { useCanvasStore } from '@/stores/canvas-store'

export function DropIndicator() {
  const dropTarget = useCanvasStore((s) => s.dropTarget)
  if (!dropTarget) return null

  // Simplistic indicator — in a real implementation we'd calculate
  // pixel positions based on the target container's bounding rect
  return (
    <div
      className="drop-indicator inside"
      style={{
        position: 'absolute',
        top: '50%',
        left: '50%',
        width: 80,
        height: 40,
        transform: 'translate(-50%, -50%)',
        pointerEvents: 'none',
        zIndex: 999,
      }}
    />
  )
}
