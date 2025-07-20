/**
 * Wrapper around hasOwnProperty. Safa against objects which define
 * their own hasOwnProperty method.
 * @param {any} obj object
 * @param {string} prop property
 * @returns {bool} true, if obj has prop
 */
export const has = (obj, prop) => obj != null && Object.prototype.hasOwnProperty.call(obj, prop)
