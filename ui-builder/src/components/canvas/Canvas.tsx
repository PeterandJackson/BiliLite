import { useCallback, useRef, useState } from 'react'
import { useDroppable } from '@dnd-kit/core'
import { CanvasViewport } from './CanvasViewport'
import { SelectionOverlay } from './SelectionOverlay'
import { DropIndicator } from './DropIndicator'
import { useCanvasStore } from '@/stores/canvas-store'
import { useComponentStore } from '@/stores/component-store'

export function Canvas() {
  const zoom = useCanvasStore((s) => s.zoom)
  const panX = useCanvasStore((s) => s.panX)
  const panY = useCanvasStore((s) => s.panY)
  const setPan = useCanvasStore((s) => s.setPan)
  const setZoom = useCanvasStore((s) => s.setZoom)
  const deviceFrame = useCanvasStore((s) => s.deviceFrame)
  const isPreviewMode = useCanvasStore((s) => s.isPreviewMode)
  const clearSelection = useComponentStore((s) => s.clearSelection)
  const rootIds = useComponentStore((s) => s.rootIds)
  const dropTarget = useCanvasStore((s) => s.dropTarget)

  const isPanning = useRef(false)
  const lastPos = useRef({ x: 0, y: 0 })
  const canvasRef = useRef<HTMLDivElement>(null)

  const frameWidth = deviceFrame?.width || 1440
  const frameHeight = deviceFrame?.height || 900

  const { setNodeRef } = useDroppable({ id: 'canvas-root' })

  const handleMouseDown = useCallback(
    (e: React.MouseEvent) => {
      // Only pan with middle mouse button or space+left click
      if (e.button === 1 || (e.button === 0 && e.altKey)) {
        e.preventDefault()
        isPanning.current = true
        lastPos.current = { x: e.clientX, y: e.clientY }
      } else if (e.target === e.currentTarget || (e.target as HTMLElement).classList.contains('canvas-area')) {
        // Click on empty canvas area clears selection
        clearSelection()
      }
    },
    [clearSelection]
  )

  const handleMouseMove = useCallback(
    (e: React.MouseEvent) => {
      if (!isPanning.current) return
      const dx = e.clientX - lastPos.current.x
      const dy = e.clientY - lastPos.current.y
      lastPos.current = { x: e.clientX, y: e.clientY }
      setPan(panX + dx, panY + dy)
    },
    [panX, panY, setPan]
  )

  const handleMouseUp = useCallback(() => {
    isPanning.current = false
  }, [])

  const handleWheel = useCallback(
    (e: React.WheelEvent) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault()
        const delta = e.deltaY > 0 ? -0.05 : 0.05
        setZoom(zoom + delta)
      } else {
        setPan(panX - e.deltaX, panY - e.deltaY)
      }
    },
    [zoom, panX, panY, setZoom, setPan]
  )

  return (
    <div
      ref={(node) => { setNodeRef(node); canvasRef.current = node as any }}
      className={`canvas-area w-full h-full ${isPanning.current ? 'grabbing' : ''}`}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onWheel={handleWheel}
      style={{ position: 'relative' }}
    >
      <CanvasViewport>
        {/* Frame */}
        <div
          className="design-frame"
          style={{
            width: deviceFrame?.width || '100%',
            height: deviceFrame?.height || '100%',
            minWidth: 100,
            minHeight: 100,
          }}
        >
          {/* Root-level components rendered inside viewport */}
        </div>
      </CanvasViewport>

      {/* Drop indicator */}
      {!isPreviewMode && dropTarget && <DropIndicator />}

      {/* Selection overlay */}
      {!isPreviewMode && <SelectionOverlay />}
    </div>
  )
}
