// Will return whether the current environment is in a regular browser
// and not CEF
export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

// Basic no operation function
export const noop = () => {};

export const formatPumpkins = (num: number) => {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}
