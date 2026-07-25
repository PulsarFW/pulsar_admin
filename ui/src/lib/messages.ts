// central NUI message router, forwards SendNUIMessage calls from client/nui.lua to the admin store

import { handleAdminMessage } from './store/admin.svelte';

interface InboundMessage {
	type?: string;
	data?: unknown;
}

function route(type: string, data: unknown) {
	const record = (data ?? {}) as Record<string, unknown>;
	handleAdminMessage(type, record);
}

/** Returns an unsubscribe function */
export function attachMessageListener(): () => void {
	const handler = (event: MessageEvent<InboundMessage>) => {
		if (!event.isTrusted) return;
		if (event.data?.type) route(event.data.type, event.data.data);
	};
	window.addEventListener('message', handler);
	return () => window.removeEventListener('message', handler);
}

export { route as applyMessage };
