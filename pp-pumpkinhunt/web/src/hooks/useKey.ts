import { useEffect, useRef, MutableRefObject } from 'react'
import { noop } from '../utils/misc'

const useKey = (key: string, handler: () => void) => {
    const savedHandler: MutableRefObject<() => void> = useRef(noop)

    useEffect(() => {
        savedHandler.current = handler
    }, [handler])

    useEffect(() => {
        const keyListener = (event: KeyboardEvent) => {
            if (event.key === key) {
                savedHandler.current()
            }
        }

        window.addEventListener('keydown', keyListener)
        return () => window.removeEventListener('keydown', keyListener)
    }, [key])
}

export default useKey
