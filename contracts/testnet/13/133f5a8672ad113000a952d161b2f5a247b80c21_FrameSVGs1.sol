// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.13;

import '../../../interfaces/IFrameSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract FrameSVGs1 is IFrameSVGs, ICategories {
	function frame_0() public pure returns (FrameData memory) {
		return FrameData('', FrameCategories.NONE, '');
	}

	function frame_1() public pure returns (FrameData memory) {
		return
			FrameData(
				'Adorned',
				FrameCategories.ADORNED,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="fr0-a" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="fr0-c" x1="0" x2="1" xlink:href="#fr0-a" y1="0" y2="0"/><linearGradient id="fr0-b" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="fr0-d" x1="0" x2="0" xlink:href="#fr0-b" y1="0" y2="1"/><linearGradient id="fr0-e" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient></defs><path d="M110 204a55.06 55.06 0 0 1-55-55V68h110v81a55.06 55.06 0 0 1-55 55Z" fill="none" stroke="#000" stroke-width="9.8"/><path d="M110 202a55.06 55.06 0 0 1-55-55V67h110v80a55.06 55.06 0 0 1-55 55Z" fill="none" stroke="url(#fr0-a)" stroke-width="10"/><path d="M55 67h110l5-5H50Z" fill="url(#fr0-c)"/><path d="m55 67 5 5h100l5-5Z" fill="url(#fr0-b)"/><path d="M165 67v80a55 55 0 0 1-110 0V67l-5-5v85a60 60 0 0 0 120 0V62Z" fill="url(#fr0-d)"/><path d="M110 202a55.06 55.06 0 0 1-55-55V67h110v80a55.06 55.06 0 0 1-55 55Z" fill="none" stroke="url(#fr0-e)"/><path d="M0 0h220v264H0z" fill="none"/>'
					)
				)
			);
	}

	function frame_2() public pure returns (FrameData memory) {
		return
			FrameData(
				'Menacing',
				FrameCategories.MENACING,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="fr1-b" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="fr1-a" x1="64.42" x2="64.42" y1="110.39" y2="110.39"><stop offset="0"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="fr1-c" x1="39.01" x2="39.01" xlink:href="#fr1-a" y1="29.99" y2="223.34"/><linearGradient id="fr1-e" x1="110" x2="85" xlink:href="#fr1-b" y1="56.74" y2="56.74"/><linearGradient id="fr1-g" x1="0" x2="1" xlink:href="#fr1-b" y1="0" y2="0"/><linearGradient id="fr1-h" x1="0" x2="1" xlink:href="#fr1-b" y1="0" y2="0"/><linearGradient gradientUnits="userSpaceOnUse" id="fr1-i" x1="110" x2="110" y1="87.5" y2="247.73"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="fr1-j" x1="110" x2="110" y1="69" y2="200"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="fr1-k" x1="57" x2="163" y1="70.5" y2="70.5"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="fr1-d" viewBox="0 0 78.01 180.47"><path d="M64.42 110.39z" fill="url(#fr1-a)"/><path d="M78 83.57v-2s-20.5-.11-18-16.64c.4-9.07 6-11.47 6-11.47v-2h-8.9c2-28.77 12.77-48.88 12.77-48.88V0S54.58 14.45 39.29 14.45H0l2 8h51v74c0 27.61-23.39 51-51 51l-2 9.72 2 23.29c.11-.41 3-18.79 12.72-22.9 8.79-3.7 14.16.12 14.16.12s.36-7.07 8-12.94S56 148.29 56 148.29v-2s-9.37-11.61-2-22.26c5.1-9.82 10.37-11.64 10.37-11.64v-2c-.15-.09-8.39-2-4.18-11.91C62 87.88 78 83.57 78 83.57Z" fill="url(#fr1-c)"/></symbol><symbol id="fr1-f" viewBox="0 0 77.01 183.03"><path d="m25.71 150.5 2.17 9.75s-5.37-3.83-14.16-.12C4 164.24 1.11 182.62 1 183l-1-27Z" fill="url(#fr1-b)"/><path d="M44.53 136.05 24.71 151.5l3.17 8.75s.36-7.07 8-12.94S55 150.85 55 150.85Z" fill="url(#fr1-b)"/><path d="M55.76 110.34 44 137.56l11 13.29s-7.08-14.45-2-24.27 10.37-11.64 10.37-11.64Z" fill="url(#fr1-b)"/><path d="m55 85.12 22 1S61 90.43 59.24 101s4.18 13.9 4.18 13.9l-7.66-3.6Z" fill="url(#fr1-b)"/><path d="M65 56s-6 2.56-6 12.5c0 14 18 17.61 18 17.61H55V55Z" fill="url(#fr1-b)"/><path d="M68.88 4.55S59 22.63 59 43.51C59 53.45 65 56 65 56H53.74l-2.83-30.87Z" fill="url(#fr1-b)"/><path d="M38.29 18C53.58 18 68.88 4.55 68.88 4.55l-18 21.58L25 21l1-9s3.41 6 12.29 6Z" fill="url(#fr1-b)"/><path d="M13.5 18c9.94 0 12.5-6 12.5-6v9.5l-26-.72L1 0s2.56 18 12.5 18Z" fill="url(#fr1-b)"/></symbol></defs><path d="M0 0h220v264H0z" fill="none"/><use height="180.47" transform="translate(108 50.54)" width="78.01" xlink:href="#fr1-d"/><use height="180.47" transform="matrix(-1 0 0 1 112 50.54)" width="78.01" xlink:href="#fr1-d"/><path d="M97.5 64C87.56 64 85 58 85 58v9.5l25-.73V46s-2.56 18-12.5 18Z" fill="url(#fr1-e)"/><use height="183.03" transform="matrix(-1 0 0 1 111 45.99)" width="77.01" xlink:href="#fr1-f"/><use height="183.03" transform="translate(109 45.99)" width="77.01" xlink:href="#fr1-f"/><path d="M97.5 64C87.56 64 85 58 85 58v9.5l25-.73V46s-2.56 18-12.5 18Z" fill="url(#fr1-g)"/><path d="M85.67 199.21l-2.55 7s5.37-3.82 14.16-.12c9.76 4.12 12.61 22.5 12.72 22.9V201.94Z" fill="url(#fr1-h)"/><path d="M170.42 132.11c-6.89-9.49-7.66-20.13-1.87-30.11-6.6-12.68-1.83-38.07-1.83-38.07S150.59 70.52 135 64c-5.46 3.26-18.75 4.7-25-1.35-6.25 6.05-19.54 4.61-25 1.35-15.59 6.52-31.72-.07-31.72-.07s4.77 25.39-1.83 38.07c5.79 10 5 20.62-1.87 30.11 5.11 4.49 7.86 15.07 3.57 26.2a41.69 41.69 0 0 1 10.66 29.11c5.07-1.46 17.59 2.48 21.38 13.1 1.9-.68 18.13.11 24.81 11.68 6.68-11.57 22.91-12.36 24.81-11.68 3.79-10.62 16.31-14.56 21.38-13.1a41.69 41.69 0 0 1 10.66-29.11c-4.29-11.13-1.54-21.71 3.57-26.2ZM161 147a51 51 0 0 1-102 0V71h102Z" fill="url(#fr1-i)"/><path d="M110 198.5A51.55 51.55 0 0 1 58.5 147V70.5h103V147a51.55 51.55 0 0 1-51.5 51.5Z" fill="none" stroke="url(#fr1-j)" stroke-width="3"/><path d="m57 69 3 3.01h100l3-3.01H57z" fill="url(#fr1-k)"/>'
					)
				)
			);
	}

	function frame_3() public pure returns (FrameData memory) {
		return
			FrameData(
				'Secured',
				FrameCategories.SECURED,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="fr2-a" x1="0" x2="0" y1="1"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="fr2-f" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="fr2-d" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="fr2-e" x1="0" x2="0" y1="1" y2="0"><stop offset=".05" stop-color="gray"/><stop offset=".17" stop-color="#fff"/><stop offset=".22" stop-color="gray"/><stop offset=".26" stop-color="#fff"/><stop offset=".33" stop-color="gray"/><stop offset=".52" stop-color="#fff"/><stop offset=".81" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="fr2-g" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="fr2-c" viewBox="0 0 71 172.66"><path d="m62.54 46.14 6.24-4.6a5.46 5.46 0 0 0 2.22-4.4V3.03A3.02 3.02 0 0 0 67.98 0H31.74a4.55 4.55 0 0 0-3.43 1.56L21.58 9.3a10.79 10.79 0 0 1-8.14 3.7H0l1 5.91h51v76c0 28.67-22.33 51-51 51l-.74 3.47.74 2.53a56.8 56.8 0 0 0 13.6-1.64 1.63 1.63 0 0 1 1.94 2.1l-5.15 15.18a1.64 1.64 0 0 1-1.55 1.1H0l1 4h10.42a7.92 7.92 0 0 0 4.8-1.62l21.28-16.25a5.05 5.05 0 0 0 1.99-4.02v-5.49a12.6 12.6 0 0 1 11.77-12.58l6.46-.43a5.01 5.01 0 0 0 4.01-2.51A69.53 69.53 0 0 0 71 95v-3.12a3.63 3.63 0 0 0-1.48-2.92l-6.98-5.15a10.79 10.79 0 0 1-4.39-8.68v-20.3a10.79 10.79 0 0 1 4.4-8.7Zm-33 110.45-10.45 7.97a1.54 1.54 0 0 1-2.4-1.7l3.57-10.94a1.54 1.54 0 0 1 2.08-.94l6.88 2.97a1.54 1.54 0 0 1 .32 2.64Zm3.44-5.34-9.7-3.56a2 2 0 0 1 .04-3.6 53.67 53.67 0 0 0 9.09-5.27 2 2 0 0 1 3.15 1.76v8.86a1.92 1.92 0 0 1-2.58 1.8ZM68 10.66v15.59a2 2 0 0 1-3.2 1.6l-8.91-6.68a2 2 0 0 1-.21-3.01l8.91-8.91A2 2 0 0 1 68 10.66ZM40.62 16H26.03a2 2 0 0 1-1.54-3.28l7.29-8.75a2.02 2.02 0 0 1 3.09 0l7.29 8.75A2 2 0 0 1 40.62 16Zm9.49-.26-7.95-9.47A2 2 0 0 1 43.7 3h16.64a2 2 0 0 1 1.41 3.41l-9.43 9.43a1.5 1.5 0 0 1-2.21-.1Zm5.42 113.66-9.75.65a2 2 0 0 1-1.76-3.15 52.9 52.9 0 0 0 5.27-9.09 2 2 0 0 1 3.6-.04l4.3 8.75a2 2 0 0 1-1.66 2.88Zm7.4-8.86a2.01 2.01 0 0 1-3.66.15l-4.93-10.03a2 2 0 0 1 .68-2.54l9.29-6.22a2 2 0 0 1 3.1 1.89 66.67 66.67 0 0 1-4.48 16.75ZM58.2 86.15l8.09 6.07a2 2 0 0 1-.09 3.26l-8.09 5.42A2 2 0 0 1 55 99.24V87.75a2 2 0 0 1 3.2-1.6ZM55 42.25v-12.5a2 2 0 0 1 3.2-1.6l8.33 6.25a2 2 0 0 1 0 3.2l-8.33 6.25a2 2 0 0 1-3.2-1.6Z" fill="url(#fr2-a)"/></symbol><filter id="fr2-b"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#fr2-b)"><use height="172.66" transform="translate(109 52.1)" width="71" xlink:href="#fr2-c"/><use height="172.66" transform="matrix(-1 0 0 1 111 52.1)" width="71" xlink:href="#fr2-c"/><path d="M132.32 196.18a53.67 53.67 0 0 0 9.09-5.27 2 2 0 0 1 3.15 1.76v8.87a1.92 1.92 0 0 1-2.59 1.8l-9.7-3.56a2 2 0 0 1 .05-3.6Zm-44.64 0a53.67 53.67 0 0 1-9.09-5.27 2 2 0 0 0-3.15 1.76v8.87a1.92 1.92 0 0 0 2.59 1.8l9.7-3.56a2 2 0 0 0-.05-3.6Z" fill="none" stroke="url(#fr2-d)"/><path d="M56 139.85v11.49a2 2 0 0 1-3.11 1.66l-8.09-5.42a2 2 0 0 1-.09-3.26l8.09-6.07a2 2 0 0 1 3.2 1.6Zm108 0v11.49a2 2 0 0 0 3.11 1.66l8.09-5.42a2 2 0 0 0 .09-3.26l-8.09-6.07a2 2 0 0 0-3.2 1.6Z" fill="none" stroke="url(#fr2-d)"/><path d="m52.8 95.95-8.33-6.25a2 2 0 0 1 0-3.2l8.33-6.25a2 2 0 0 1 3.2 1.6v12.5a2 2 0 0 1-3.2 1.6Zm114.4 0 8.33-6.25a2 2 0 0 0 0-3.2l-8.33-6.25a2 2 0 0 0-3.2 1.6v12.5a2 2 0 0 0 3.2 1.6Z" fill="none" stroke="url(#fr2-d)"/><path d="m53.81 178.62 4.3-8.75a2 2 0 0 1 3.6.04 52.9 52.9 0 0 0 5.27 9.09 2 2 0 0 1-1.76 3.15l-9.75-.65a2 2 0 0 1-1.66-2.88Zm112.38 0-4.3-8.75a2 2 0 0 0-3.6.04 52.9 52.9 0 0 1-5.27 9.09 2 2 0 0 0 1.76 3.15l9.75-.65a2 2 0 0 0 1.66-2.88Z" fill="none" stroke="url(#fr2-d)"/><path d="M43.59 155.89a2 2 0 0 1 3.1-1.9l9.29 6.23a2 2 0 0 1 .68 2.54l-4.93 10.03a2.01 2.01 0 0 1-3.66-.15 66.67 66.67 0 0 1-4.48-16.75Zm132.82 0a2 2 0 0 0-3.1-1.9l-9.29 6.23a2 2 0 0 0-.68 2.54l4.93 10.03a2.01 2.01 0 0 0 3.66-.15 66.67 66.67 0 0 0 4.48-16.75Z" fill="none" stroke="url(#fr2-d)"/><path d="m68.84 58.37-7.95 9.47a1.5 1.5 0 0 1-2.21.1l-9.43-9.43a2 2 0 0 1 1.41-3.41H67.3a2 2 0 0 1 1.54 3.27Zm7.29-2.3-7.29 8.75a2 2 0 0 0 1.54 3.28h14.59a2 2 0 0 0 1.54-3.28l-7.29-8.75a2.02 2.02 0 0 0-3.09 0Zm75.03 2.3 7.95 9.47a1.5 1.5 0 0 0 2.21.1l9.43-9.43a2 2 0 0 0-1.41-3.41H152.7a2 2 0 0 0-1.54 3.27Zm-10.38-2.3-7.29 8.75a2 2 0 0 0 1.54 3.28h14.59a2 2 0 0 0 1.54-3.28l-7.29-8.75a2.02 2.02 0 0 0-3.09 0Z" fill="none" stroke="url(#fr2-d)"/><path d="m90.74 204.02 3.57 10.93a1.54 1.54 0 0 1-2.4 1.7l-10.45-7.96a1.54 1.54 0 0 1 .33-2.64l6.88-2.97a1.54 1.54 0 0 1 2.07.94Zm38.52 0-3.57 10.93a1.54 1.54 0 0 0 2.4 1.7l10.45-7.96a1.54 1.54 0 0 0-.33-2.64l-6.88-2.97a1.54 1.54 0 0 0-2.08.94ZM110 204a56.8 56.8 0 0 1-13.6-1.65 1.63 1.63 0 0 0-1.94 2.11l5.15 15.17a1.64 1.64 0 0 0 1.55 1.11h17.68a1.64 1.64 0 0 0 1.55-1.1l5.15-15.18a1.63 1.63 0 0 0-1.94-2.1A56.81 56.81 0 0 1 110 204Z" fill="none" stroke="url(#fr2-d)"/><path d="M43 78.35a2 2 0 0 0 3.2 1.6l8.91-6.68a2 2 0 0 0 .21-3.01l-8.91-8.91a2 2 0 0 0-3.41 1.4Z" fill="none" stroke="url(#fr2-d)"/><path d="M177 62.76a2 2 0 0 0-3.41-1.41l-8.91 8.9a2 2 0 0 0 .21 3.02l8.91 6.68a2 2 0 0 0 3.2-1.6Z" fill="none" stroke="url(#fr2-d)"/><path d="m171.54 98.23 6.24-4.6a5.46 5.46 0 0 0 2.22-4.39V55.12a3.02 3.02 0 0 0-3.02-3.02h-36.24a4.54 4.54 0 0 0-3.43 1.56l-6.73 7.73a10.79 10.79 0 0 1-8.14 3.7H97.56a10.79 10.79 0 0 1-8.14-3.7l-6.73-7.73a4.54 4.54 0 0 0-3.43-1.56H43.02A3.02 3.02 0 0 0 40 55.12v34.12a5.46 5.46 0 0 0 2.22 4.4l6.24 4.6a10.79 10.79 0 0 1 4.39 8.68v20.3a10.79 10.79 0 0 1-4.4 8.7l-6.98 5.14a3.63 3.63 0 0 0-1.47 2.91v3.13a69.53 69.53 0 0 0 9.27 34.75 5.01 5.01 0 0 0 4 2.51l6.47.43a12.6 12.6 0 0 1 11.77 12.58v5.5a5.06 5.06 0 0 0 1.99 4l21.27 16.26a7.92 7.92 0 0 0 4.8 1.63h20.85a7.92 7.92 0 0 0 4.8-1.63l21.28-16.25a5.05 5.05 0 0 0 1.99-4.02v-5.49a12.6 12.6 0 0 1 11.77-12.58l6.46-.43a5.01 5.01 0 0 0 4.01-2.51A69.53 69.53 0 0 0 180 147.1v-3.12a3.63 3.63 0 0 0-1.48-2.92l-6.98-5.15a10.79 10.79 0 0 1-4.39-8.68v-20.31a10.79 10.79 0 0 1 4.4-8.69Z" fill="none" stroke="url(#fr2-e)" stroke-width="2"/><path d="M161 70v77a51 51 0 1 1-102 0V70" fill="none" stroke="url(#fr2-f)" stroke-width="2"/></g><path d="M160 72.01H60l-2-2h104l-2 2z" fill="url(#fr2-g)"/>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFrameSVGs {
	struct FrameData {
		string title;
		ICategories.FrameCategories frameType;
		string svgString;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICategories {
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}

	enum FrameCategories {
		NONE,
		ADORNED,
		MENACING,
		SECURED,
		FLORIATED,
		EVERLASTING
	}
}