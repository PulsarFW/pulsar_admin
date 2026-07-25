<!-- hand-picks a curated icon set covering nav icons, titlebar actions, table sort indicators, and pagination/status glyphs -->
<script lang="ts">
	import {
		faHouse,
		faUserLarge,
		faUserLargeSlash,
		faPeopleGroup,
		faCar,
		faCarSide,
		faEyeSlash,
		faIdBadge,
		faLinkSlash,
		faXmark,
		faMagnifyingGlass,
		faSort,
		faSortUp,
		faSortDown,
		faArrowsRotate,
		faChevronLeft,
		faChevronRight,
		faChevronDown,
		faCircleCheck,
		faCircleExclamation,
		faCopy,
		faCompress,
		faExpand,
		faGhost,
		faBoxesStacked,
		faBriefcase,
		faDoorOpen,
		faPlus,
		faTrash,
		faLocationCrosshairs,
		type IconDefinition,
	} from '@fortawesome/free-solid-svg-icons';

	const ICONS: Record<string, IconDefinition> = {
		house: faHouse,
		'user-large': faUserLarge,
		'user-large-slash': faUserLargeSlash,
		people: faPeopleGroup,
		car: faCar,
		'car-side': faCarSide,
		'eye-slash': faEyeSlash,
		'id-badge': faIdBadge,
		'link-slash': faLinkSlash,
		xmark: faXmark,
		'magnifying-glass': faMagnifyingGlass,
		sort: faSort,
		'sort-up': faSortUp,
		'sort-down': faSortDown,
		'arrows-rotate': faArrowsRotate,
		'chevron-left': faChevronLeft,
		'chevron-right': faChevronRight,
		'chevron-down': faChevronDown,
		'circle-check': faCircleCheck,
		'circle-exclamation': faCircleExclamation,
		copy: faCopy,
		compress: faCompress,
		expand: faExpand,
		ghost: faGhost,
		'boxes-stacked': faBoxesStacked,
		briefcase: faBriefcase,
		'door-open': faDoorOpen,
		plus: faPlus,
		trash: faTrash,
		'location-crosshairs': faLocationCrosshairs,
	};

	let { name, size = '1em' }: { name: string; size?: string } = $props();

	const icon = $derived(ICONS[name] ?? faCircleExclamation);
	const path = $derived(icon.icon[4] as string);
	const viewBox = $derived(`0 0 ${icon.icon[0]} ${icon.icon[1]}`);
</script>

<svg {viewBox} width={size} height={size} fill="currentColor" aria-hidden="true">
	<path d={path} />
</svg>
