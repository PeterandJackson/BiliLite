// ── Style Value ──────────────────────────────────────────────

export type CSSUnit = 'px' | '%' | 'em' | 'rem' | 'vh' | 'vw' | 'auto'

export interface StyleValue {
  value: number
  unit: CSSUnit
}

export interface BoxModel {
  top: StyleValue
  right: StyleValue
  bottom: StyleValue
  left: StyleValue
}

export type StyleProperties = Partial<{
  // Layout
  width: StyleValue
  height: StyleValue
  minWidth: StyleValue
  minHeight: StyleValue
  maxWidth: StyleValue
  maxHeight: StyleValue
  margin: BoxModel
  padding: BoxModel
  // Positioning (for absolute)
  x: StyleValue
  y: StyleValue
  position: 'absolute' | 'relative' | 'static'
  // Flex
  display: 'block' | 'flex' | 'grid' | 'inline' | 'inline-block'
  flexDirection: 'row' | 'column' | 'row-reverse' | 'column-reverse'
  flexWrap: 'nowrap' | 'wrap' | 'wrap-reverse'
  justifyContent: 'flex-start' | 'flex-end' | 'center' | 'space-between' | 'space-around' | 'space-evenly'
  alignItems: 'flex-start' | 'flex-end' | 'center' | 'stretch' | 'baseline'
  gap: StyleValue
  flexGrow: number
  flexShrink: number
  flexBasis: StyleValue
  // Grid
  gridTemplateColumns: string
  gridTemplateRows: string
  gridColumnGap: StyleValue
  gridRowGap: StyleValue
  // Visual
  backgroundColor: string
  color: string
  opacity: number
  // Typography
  fontFamily: string
  fontSize: StyleValue
  fontWeight: number | string
  fontStyle: 'normal' | 'italic'
  textAlign: 'left' | 'center' | 'right' | 'justify'
  lineHeight: StyleValue | number
  letterSpacing: StyleValue
  textDecoration: 'none' | 'underline' | 'line-through'
  // Border
  borderWidth: StyleValue
  borderColor: string
  borderStyle: 'solid' | 'dashed' | 'dotted' | 'none'
  borderRadius: StyleValue
  borderTopLeftRadius: StyleValue
  borderTopRightRadius: StyleValue
  borderBottomLeftRadius: StyleValue
  borderBottomRightRadius: StyleValue
  // Shadow
  boxShadow: string
  // Transform
  transform: string
  // Cursor
  cursor: string
  // Overflow
  overflow: 'visible' | 'hidden' | 'scroll' | 'auto'
  // Transition
  transition: string
  // Z-index
  zIndex: number
}>

// ── Component Types ───────────────────────────────────────────

export type ComponentCategory = 'layout' | 'forms' | 'content' | 'media'

export interface PropertyOption {
  label: string
  value: string
}

export interface PropertySchema {
  name: string
  label: string
  type: 'string' | 'number' | 'boolean' | 'color' | 'select' | 'font' | 'size' | 'textarea'
  defaultValue: unknown
  options?: PropertyOption[]
  validation?: {
    min?: number
    max?: number
    pattern?: string
  }
  dependsOn?: string
}

export interface ComponentDefinition {
  type: string
  displayName: string
  category: ComponentCategory
  icon: string
  defaultProps: Record<string, unknown>
  defaultStyles: StyleProperties
  allowedChildren: boolean | string[]
  allowedParents: string[] | null
  properties: PropertySchema[]
  htmlTag: string
  isContainer: boolean
  selfClosing?: boolean
}

// ── Component Instance ────────────────────────────────────────

export interface ComponentInstance {
  id: string
  type: string
  props: Record<string, unknown>
  styles: StyleProperties
  children: string[] // child IDs
  parentId: string | null
  // Runtime cache (not serialized)
  _locked?: boolean
  _hidden?: boolean
}

// ── Project ───────────────────────────────────────────────────

export interface ProjectPage {
  id: string
  name: string
  route: string
  rootIds: string[]
}

export interface ProjectMetadata {
  name: string
  createdAt: string
  updatedAt: string
  canvasWidth: number
  canvasHeight: number
}

export interface ProjectData {
  version: string
  metadata: ProjectMetadata
  pages: ProjectPage[]
  components: Record<string, ComponentInstance>
}
