import { create } from 'zustand'
import type { AlignmentGuide, DropTargetInfo, DeviceFrame } from '@/types'

interface CanvasStore {
  zoom: number
  panX: number
  panY: number
  deviceFrame: DeviceFrame | null
  guides: AlignmentGuide[]
  dropTarget: DropTargetInfo | null
  isPreviewMode: boolean
  showGuides: boolean

  setZoom: (zoom: number) => void
  setPan: (x: number, y: number) => void
  setDeviceFrame: (frame: DeviceFrame | null) => void
  setGuides: (guides: AlignmentGuide[]) => void
  setDropTarget: (target: DropTargetInfo | null) => void
  togglePreviewMode: () => void
  setShowGuides: (show: boolean) => void
  zoomToFit: (canvasWidth: number, canvasHeight: number, viewportWidth: number, viewportHeight: number) => void
  resetView: () => void
}

export const useCanvasStore = create<CanvasStore>()((set) => ({
  zoom: 1,
  panX: 40,
  panY: 40,
  deviceFrame: { name: 'Desktop', width: 1440, height: 900 },
  guides: [],
  dropTarget: null,
  isPreviewMode: false,
  showGuides: true,

  setZoom: (zoom) => set({ zoom: Math.max(0.1, Math.min(5, zoom)) }),
  setPan: (panX, panY) => set({ panX, panY }),
  setDeviceFrame: (frame) => set({ deviceFrame: frame }),
  setGuides: (guides) => set({ guides }),
  setDropTarget: (target) => set({ dropTarget: target }),
  togglePreviewMode: () => set((s) => ({ isPreviewMode: !s.isPreviewMode })),
  setShowGuides: (show) => set({ showGuides: show }),

  zoomToFit: (canvasWidth, canvasHeight, viewportWidth, viewportHeight) => {
    const pad = 80
    const availW = viewportWidth - pad * 2
    const availH = viewportHeight - pad * 2
    const scale = Math.min(availW / canvasWidth, availH / canvasHeight, 1.5)
    const panX = (viewportWidth - canvasWidth * scale) / 2
    const panY = (viewportHeight - canvasHeight * scale) / 2
    set({ zoom: scale, panX, panY })
  },

  resetView: () => set({ zoom: 1, panX: 40, panY: 40 }),
}))
