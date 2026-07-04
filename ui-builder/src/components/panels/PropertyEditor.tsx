import { useCallback, useMemo } from 'react'
import { useComponentStore } from '@/stores/component-store'
import { getComponentDefinition } from '@/core/component-registry'
import type { StyleValue } from '@/types'

function SizeInput({ value, onChange }: { value: StyleValue | undefined; onChange: (sv: StyleValue) => void }) {
  const v = value ?? { value: 0, unit: 'px' }
  return (
    <div className="flex gap-1">
      <input
        type="number"
        className="property-input flex-1"
        value={v.value}
        onChange={(e) => onChange({ ...v, value: Number(e.target.value) || 0 })}
      />
      <select
        className="property-input w-16"
        value={v.unit}
        onChange={(e) => onChange({ ...v, unit: e.target.value as any })}
      >
        <option value="px">px</option>
        <option value="%">%</option>
        <option value="em">em</option>
        <option value="rem">rem</option>
        <option value="vh">vh</option>
        <option value="vw">vw</option>
        <option value="auto">auto</option>
      </select>
    </div>
  )
}

export function PropertyEditor() {
  const selectedIds = useComponentStore((s) => s.selectedIds)
  const components = useComponentStore((s) => s.components)
  const updateComponentProps = useComponentStore((s) => s.updateComponentProps)

  const selectedId = useMemo(() => {
    if (selectedIds.size !== 1) return null
    return [...selectedIds][0]
  }, [selectedIds])

  const component = selectedId ? components[selectedId] : null
  const def = component ? getComponentDefinition(component.type) : null

  const handleChange = useCallback(
    (name: string, value: unknown) => {
      if (!selectedId) return
      updateComponentProps(selectedId, { [name]: value })
    },
    [selectedId, updateComponentProps]
  )

  if (selectedIds.size === 0) {
    return (
      <div className="p-4 text-center text-gray-500 text-sm">
        <p>No component selected.</p>
        <p className="mt-1 text-xs">Click a component on the canvas to edit its properties.</p>
      </div>
    )
  }

  if (selectedIds.size > 1) {
    return (
      <div className="p-4 text-center text-gray-500 text-sm">
        <p>{selectedIds.size} components selected.</p>
        <p className="mt-1 text-xs">Select a single component to edit its properties.</p>
      </div>
    )
  }

  if (!component || !def) {
    return (
      <div className="p-4 text-center text-gray-500 text-sm">
        <p>Unable to find component.</p>
      </div>
    )
  }

  return (
    <div className="p-3">
      <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
        {def.displayName} Properties
      </div>
      <div className="text-xs text-gray-500 mb-3">
        ID: {component.id} · Type: {component.type}
      </div>

      {def.properties.map((prop) => {
        const currentValue = component.props[prop.name]

        return (
          <div key={prop.name} className="property-row">
            <label className="property-label">{prop.label}</label>

            {prop.type === 'string' && (
              <input
                className="property-input"
                type="text"
                value={String(currentValue ?? prop.defaultValue ?? '')}
                onChange={(e) => handleChange(prop.name, e.target.value)}
              />
            )}

            {prop.type === 'textarea' && (
              <textarea
                className="property-input"
                rows={3}
                value={String(currentValue ?? prop.defaultValue ?? '')}
                onChange={(e) => handleChange(prop.name, e.target.value)}
              />
            )}

            {prop.type === 'number' && (
              <input
                className="property-input"
                type="number"
                min={prop.validation?.min}
                max={prop.validation?.max}
                value={Number(currentValue ?? prop.defaultValue ?? 0)}
                onChange={(e) => handleChange(prop.name, Number(e.target.value))}
              />
            )}

            {prop.type === 'boolean' && (
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={Boolean(currentValue ?? prop.defaultValue ?? false)}
                  onChange={(e) => handleChange(prop.name, e.target.checked)}
                  className="w-4 h-4"
                />
                <span className="text-xs text-gray-400">
                  {String(currentValue ?? prop.defaultValue ?? false) === 'true' ? 'Yes' : 'No'}
                </span>
              </label>
            )}

            {prop.type === 'color' && (
              <div className="flex gap-1 flex-1">
                <input
                  className="property-input flex-1"
                  type="text"
                  value={String(currentValue ?? prop.defaultValue ?? '#000000')}
                  onChange={(e) => handleChange(prop.name, e.target.value)}
                />
                <input
                  type="color"
                  value={String(currentValue ?? prop.defaultValue ?? '#000000')}
                  onChange={(e) => handleChange(prop.name, e.target.value)}
                  className="w-8 h-8 rounded cursor-pointer border border-white/10 bg-transparent"
                />
              </div>
            )}

            {prop.type === 'select' && prop.options && (
              <select
                className="property-input"
                value={String(currentValue ?? prop.defaultValue ?? '')}
                onChange={(e) => {
                  // Try to preserve number type
                  const num = Number(e.target.value)
                  handleChange(prop.name, isNaN(num) ? e.target.value : num)
                }}
              >
                {prop.options.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            )}

            {prop.type === 'size' && (
              <div className="flex-1">
                <SizeInput
                  value={(currentValue as StyleValue) ?? (prop.defaultValue as StyleValue)}
                  onChange={(sv) => handleChange(prop.name, sv)}
                />
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
