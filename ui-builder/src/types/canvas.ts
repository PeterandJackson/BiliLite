export interface ViewportTransform {
  zoom: number
  panX: number
  panY: number
}

export interface AlignmentGuide {
  orientation: 'horizontal' | 'vertical'
  position: number
  start: number
  end: number
  type: 'edge' | 'center'
  snappingComponentIds: string[]
}

export interface DropTargetInfo {
  parentId: string | null
  index: number
  dropPosition: 'inside' | 'before' | 'after'
}

export interface DeviceFrame {
  name: string
  width: number
  height: number
}

export const DEVICE_FRAMES: DeviceFrame[] = [
  { name: 'Desktop', width: 1440, height: 900 },
  { name: 'Desktop HD', width: 1920, height: 1080 },
  { name: 'Tablet', width: 768, height: 1024 },
  { name: 'Mobile', width: 375, height: 812 },
  { name: 'Freeform', width: 0, height: 0 },
]
