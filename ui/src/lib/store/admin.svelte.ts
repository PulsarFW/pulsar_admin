// single domain store: auth/permission state (from SET_USERDATA), local page navigation (a simple page+params stack, this is a single NUI overlay not a deep-linkable app), and the toast queue

import type { PageId } from '../../config';
import type { AdminUser } from '../types';

interface NavEntry {
	page: PageId;
	params: Record<string, string>;
}

export const adminState = $state({
	hidden: true,
	opacity: false,
	pickerActive: false,
	// compact mode: a small corner-anchored widget instead of the big centered panel, not persisted across sessions
	compact: false,
	user: null as AdminUser | null,
	permission: '',
	permissionName: '',
	permissionLevel: 0,
	page: 'dashboard' as PageId,
	pageParams: {} as Record<string, string>,
	navStack: [] as NavEntry[],
});

export interface Toast {
	id: number;
	kind: 'success' | 'error';
	message: string;
}

export const toastState = $state({ toasts: [] as Toast[] });

let nextToastId = 1;
export const toast = {
	success(message: string) {
		push('success', message);
	},
	error(message: string) {
		push('error', message);
	},
};

function push(kind: 'success' | 'error', message: string) {
	const id = nextToastId++;
	toastState.toasts = [...toastState.toasts, { id, kind, message }];
	setTimeout(() => dismissToast(id), 4000);
}

export function dismissToast(id: number) {
	toastState.toasts = toastState.toasts.filter((t) => t.id !== id);
}

export function handleAdminMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SET_USERDATA':
			adminState.user = data.user as AdminUser;
			adminState.permission = data.permission as string;
			adminState.permissionName = data.permissionName as string;
			adminState.permissionLevel = data.permissionLevel as number;
			break;
		case 'APP_SHOW':
			adminState.hidden = false;
			adminState.opacity = false;
			adminState.pickerActive = false;
			break;
		case 'APP_HIDE':
			adminState.hidden = true;
			adminState.opacity = false;
			adminState.pickerActive = false;
			break;
		case 'PICKER_START':
			adminState.pickerActive = true;
			break;
		case 'PICKER_END':
			adminState.pickerActive = false;
			break;
		// execCommand works unfocused (this fires from /cpcoords while the panel is hidden), unlike navigator.clipboard
		case 'COPY': {
			const text = (data.data as string) ?? '';
			const textarea = document.createElement('textarea');
			textarea.value = text;
			textarea.style.position = 'fixed';
			textarea.style.opacity = '0';
			document.body.appendChild(textarea);
			textarea.focus();
			textarea.select();
			try {
				document.execCommand('copy');
			} catch {
				navigator.clipboard.writeText(text).catch(() => {});
			}
			document.body.removeChild(textarea);
			break;
		}
	}
}

/** Pushes the current page onto the back-stack, then navigates forward */
export function navigate(page: PageId, params: Record<string, string> = {}) {
	adminState.navStack = [...adminState.navStack, { page: adminState.page, params: adminState.pageParams }];
	adminState.page = page;
	adminState.pageParams = params;
}

// used once, after a successful kick, to return to wherever the admin came from
export function goBack() {
	if (adminState.navStack.length === 0) return;
	const prev = adminState.navStack[adminState.navStack.length - 1];
	adminState.navStack = adminState.navStack.slice(0, -1);
	adminState.page = prev.page;
	adminState.pageParams = prev.params;
}

export function setOpacity(state: boolean) {
	if (!adminState.hidden) adminState.opacity = state;
}

// Items/Jobs/Doors are panel-only, bounce back to dashboard if compact gets toggled on while sitting on one
export function toggleCompact() {
	adminState.compact = !adminState.compact;
	if (adminState.compact && (adminState.page === 'items' || adminState.page === 'jobs' || adminState.page === 'doors')) {
		adminState.page = 'dashboard';
		adminState.pageParams = {};
	}
}
