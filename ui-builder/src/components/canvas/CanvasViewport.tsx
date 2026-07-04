import { type ReactNode, useMemo } from 'react'
import { useCanvasStore } from '@/stores/canvas-store'
import { useComponentStore } from '@/stores/component-store'
import { CanvasComponent } from '@/components/renderer/CanvasComponent'

export function CanvasViewport({ children }: { children: ReactNode }) {
  const zoom = useCanvasStore((s) => s.zoom)
  const panX = useCanvasStore((s) => s.panX)
  const panY = useCanvasStore((s) => s.panY)
  const rootIds = useComponentStore((s) => s.rootIds)

  const transform = useMemo(
    () => `scale(${zoom})`,
    [zoom]
  )

  return (
    <div
      className="canvas-viewport"
      style={{
        transform,
        left: panX,
        top: panY,
      }}
    >
      {/* Design frame */}
      <div
        style={{
          position: 'relative',
          // Root components rendered here
        }}
      >
        {rootIds.map((id) => (
          <CanvasComponent key={id} id={id} />
        ))}
      </div>

      {/* Alignment guides (placeholder) */}
    </div>
  )
}
