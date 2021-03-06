// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs18 is IHardwareSVGs, ICategories {
	function hardware_69() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Four Suns',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h69-a" x1="10.73" x2="10.73" y1="16383.81" y2="16388.96"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h69-b" x1="4.62" x2="20.09" y1="16391.86" y2="16385.5"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.49" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h69-c" x1="4.04" x2="20.28" y1="16394.14" y2="16386.35"><stop offset="0" stop-color="#fff"/><stop offset="0.49" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h69-d" x1="17.71" x2="17.71" xlink:href="#h69-a" y1="9.13" y2="20.57"/><linearGradient gradientUnits="userSpaceOnUse" id="h69-e" x1="21.98" x2="30.49" y1="16.67" y2="16.67"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h69-f" x1="17.71" x2="17.71" xlink:href="#h69-e" y1="33.06" y2="2.37"/><filter id="h69-g" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h69-i" viewBox="0 0 21.47 10.73"><path d="M21.47,10.73A36.77,36.77,0,0,0,10.61,7.79h0L0,10.73H21.47Z" fill="url(#h69-a)"/><path d="M21.47,10.73c-3.26-5.8-8.51-5.36-13.71-9C6.08.77,4.29,2.58,2.88,0c.65,3.06,2.64,2.28,3.93,3S7.7,6.13,9.68,7.35a4.68,4.68,0,0,0,.93.44Z" fill="url(#h69-b)"/><path d="M8,2.28c1.49.87.91,2.14,3.2,3.46s6.91-.84,10.28,5c-1.84-3.17-3.77-5.85-7.77-7.1a2.67,2.67,0,0,1-1.91,0C10.17,2.65,10.42,2.07,8.49,1S4.85,2.61,2.88,0C3.86,3,6.31,1.32,8,2.28Z" fill="url(#h69-c)"/></symbol><symbol id="h69-h" viewBox="0 0 35.43 35.43"><path d="M9.43,20.34,0,17.72a109.07,109.07,0,0,1,17.71,0C11.7,17.72,9.43,20.34,9.43,20.34Zm17.24-.19,8.76-2.43H17.71Z" fill="url(#h69-d)"/><path d="M26,15.09l9.43,2.63a74,74,0,0,1-17.72,0C23.73,17.72,26,15.09,26,15.09Z" fill="url(#h69-e)"/><path d="M11.3,11.85,8.86,2.37a72.76,72.76,0,0,1,8.85,15.35C14.71,12.5,11.3,11.85,11.3,11.85Zm8.29-2.62,7-6.86a83,83,0,0,1-8.86,15.35C20.72,12.5,19.59,9.23,19.59,9.23Zm4.54,14.35,2.44,9.48a59.19,59.19,0,0,1-8.86-15.34C20.72,22.93,24.13,23.58,24.13,23.58ZM15.84,26.2l-7,6.86a92.44,92.44,0,0,1,8.85-15.34C14.71,22.93,15.84,26.2,15.84,26.2Z" fill="url(#h69-f)"/><use height="10.73" transform="translate(0 8.86) scale(0.83)" width="21.47" xlink:href="#h69-i"/><use height="10.73" transform="translate(16.53 -2.06) rotate(60) scale(0.83)" width="21.47" xlink:href="#h69-i"/><use height="10.73" transform="translate(34.24 6.8) rotate(120) scale(0.83)" width="21.47" xlink:href="#h69-i"/><use height="10.73" transform="translate(35.43 26.57) rotate(180) scale(0.83)" width="21.47" xlink:href="#h69-i"/><use height="10.73" transform="translate(18.9 37.49) rotate(-120) scale(0.83)" width="21.47" xlink:href="#h69-i"/><use height="10.73" transform="matrix(0.41, -0.71, 0.71, 0.41, 1.19, 28.63)" width="21.47" xlink:href="#h69-i"/></symbol></defs><g filter="url(#h69-g)"><use height="35.43" transform="translate(92.28 144.28)" width="35.43" xlink:href="#h69-h"/><use height="35.43" transform="translate(92.28 84.28)" width="35.43" xlink:href="#h69-h"/><use height="35.43" transform="translate(67.28 114.28)" width="35.43" xlink:href="#h69-h"/><use height="35.43" transform="translate(117.28 114.28)" width="35.43" xlink:href="#h69-h"/></g>'
					)
				)
			);
	}

	function hardware_70() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Two Books',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16419.13)" gradientUnits="userSpaceOnUse" id="h70-a" x2="57.11" y1="16399.9" y2="16399.9"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16419.13)" gradientUnits="userSpaceOnUse" id="h70-b" x1="28.55" x2="28.55" y1="16365.17" y2="16416.3"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h70-c" x1="0.25" x2="56.86" y1="18.51" y2="18.51"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h70-d" x1="28.56" x2="28.56" y1="21.35" y2="32.47"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h70-e" x1="28.56" x2="28.56" xlink:href="#h70-d" y1="22.9" y2="3.98"/><linearGradient gradientUnits="userSpaceOnUse" id="h70-f" x1="7.96" x2="49.15" y1="14.96" y2="14.96"><stop offset="0" stop-color="gray"/><stop offset="0.35" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="0.65" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h70-g" x1="28.55" x2="28.55" xlink:href="#h70-b" y1="30.32" y2="0"/><filter id="h70-h" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h70-i" viewBox="0 0 57.11 35.13"><path d="M22.94,35.13l-.1-1.39.37-1.17H3.06V28.65H2.47a2.47,2.47,0,1,1,0-4.94h.59V12.89H2.47A2.47,2.47,0,0,1,2.47,8h.59V4.16l.77-.84H53.28l.77.84V8h.59a2.47,2.47,0,0,1,0,4.94h-.59V23.71h.59a2.47,2.47,0,0,1,0,4.94h-.59v3.92H33.9l.37,1.17-.1,1.39Z" fill="url(#h70-a)"/><path d="M54.64,23.28H53.06V11.46h1.58a2,2,0,0,0,0-3.94H53.06v-4h-49v4H2.47a2,2,0,0,0,0,3.94H4.05V23.28H2.47a2,2,0,1,0,0,3.94H4.05v3.94H23.83l-.48,2.39H33.76l-.48-2.39H53.06V27.22h1.58a2,2,0,0,0,0-3.94Z" fill="url(#h70-b)" stroke="url(#h70-c)" stroke-width="0.5"/><path d="M31.71,29.94l.48,2.39H24.91l.49-2.39H5.27l2.85-4.15,41,.16,2.69,4Z" fill="url(#h70-d)"/><path d="M8,.25,5.27,3.57V29.94l5.38-8ZM46.46,22l5.38,8V3.57L49.15.25Z" fill="url(#h70-e)"/><path d="M22.41,26H8V.25H22.41c3.48,0,5.51,1,6.15,3.17C29.23,1.27,31.25.25,34.7.25H49.15V26H34.7a6.28,6.28,0,0,0-6.14,3.72A7,7,0,0,0,22.41,26Z" fill="url(#h70-f)" stroke="url(#h70-g)" stroke-width="0.5"/></symbol></defs><g filter="url(#h70-h)"><use height="35.13" transform="translate(81.45 90.54)" width="57.11" xlink:href="#h70-i"/><use height="35.13" transform="translate(81.45 135.54)" width="57.11" xlink:href="#h70-i"/></g>'
					)
				)
			);
	}

	function hardware_71() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Orle of Chains',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="translate(5.84 -1.2)" gradientUnits="userSpaceOnUse" id="h71-a" x1="-5.84" x2="5.84" y1="2.76" y2="2.76"><stop offset="0" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h71-h" x1="5.84" x2="-5.84" xlink:href="#h71-a" y1="1.83" y2="1.83"/><linearGradient gradientUnits="userSpaceOnUse" id="h71-b" x1="8.88" x2="8.88" y2="12"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient id="h71-e" x1="8.88" x2="8.88" xlink:href="#h71-b" y1="10.42" y2="1.5"/><linearGradient id="h71-c" x1="6.44" x2="6.44" xlink:href="#h71-b" y2="12.88"/><linearGradient id="h71-d" x1="6.44" x2="6.44" xlink:href="#h71-b" y1="11.4" y2="1.48"/><symbol id="h71-g" viewBox="0 0 12.88 12.88"><path d="M6.44 11.63a5.19 5.19 0 1 1 5.19-5.19 5.2 5.2 0 0 1-5.19 5.19Z" fill="none" stroke="url(#h71-c)" stroke-miterlimit="10" stroke-width="2.5"/><circle cx="6.44" cy="6.44" fill="none" r="4.19" stroke="url(#h71-d)" stroke-miterlimit="10" stroke-width="1.55"/></symbol><symbol id="h71-f" viewBox="0 0 17.75 12"><path d="M6 10.75a4.75 4.75 0 0 1 0-9.5h5.75a4.75 4.75 0 0 1 0 9.5Z" fill="none" stroke="url(#h71-b)" stroke-miterlimit="10" stroke-width="2.5"/><path d="M11.79 2.25H6a3.71 3.71 0 0 0 0 7.42h5.83a3.71 3.71 0 1 0 0-7.42Z" fill="none" stroke="url(#h71-e)" stroke-miterlimit="10" stroke-width="1.5"/></symbol><symbol id="h71-j" viewBox="0 0 34.31 104.61"><use height="12" transform="rotate(-29.96 179.8 49.53)" width="17.75" xlink:href="#h71-f"/><use height="12" transform="matrix(0 -1 -1 0 33.88 74.31)" width="17.75" xlink:href="#h71-f"/><use height="12" transform="matrix(0 -1 -1 0 33.88 35.81)" width="17.75" xlink:href="#h71-f"/><use height="12" transform="translate(0 .44)" width="17.75" xlink:href="#h71-f"/><use height="12.88" transform="translate(16.98 77.7)" width="12.88" xlink:href="#h71-g"/><use height="12.88" transform="translate(21.44)" width="12.88" xlink:href="#h71-g"/><use height="12.88" transform="translate(21.44 40)" width="12.88" xlink:href="#h71-g"/></symbol><symbol id="h71-i" viewBox="0 0 11.68 2.5"><path d="m11.68 1.25-1.2 1.25H1.2L0 1.25 5.84.62Z" fill="url(#h71-a)"/><path d="m10.48 0 1.2 1.25H0L1.2 0Z" fill="url(#h71-h)"/></symbol><symbol id="h71-k" viewBox="0 0 37.01 98.95"><use height="2.5" transform="matrix(-1.1 0 0 1 12.84 0)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(-1.09 0 0 1 33.82 0)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(0 1.14 -1 0 37.01 42.97)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(0 1.17 -1 0 37.01 25.81)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(0 1.28 -1 0 37.01 2.89)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(-.3 1.14 -.97 -.25 36.67 64.43)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(-.82 .84 -.72 -.7 31.83 81.2)" width="11.68" xlink:href="#h71-i"/><use height="2.5" transform="matrix(-1.27 .35 -.27 -.96 15.27 95.27)" width="11.68" xlink:href="#h71-i"/></symbol><symbol id="h71-m" viewBox="0 0 42.2 104.61"><use height="104.61" transform="translate(7.88)" width="34.32" xlink:href="#h71-j"/><use height="98.95" transform="translate(0 5.18)" width="37.01" xlink:href="#h71-k"/></symbol><filter id="h71-l"><feDropShadow dx="0" dy="1.5" stdDeviation="0"/></filter></defs><g filter="url(#h71-l)"><use height="12.88" transform="translate(103.56 80.56)" width="12.88" xlink:href="#h71-g"/><use height="12.88" transform="translate(103.56 177.56)" width="12.88" xlink:href="#h71-g"/><use height="104.61" transform="translate(111.74 80.56)" width="42.2" xlink:href="#h71-m"/><use height="104.61" transform="matrix(-1 0 0 1 108.26 80.56)" width="42.2" xlink:href="#h71-m"/></g>'
					)
				)
			);
	}

	function hardware_72() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Crancelin',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h72-a" x1="7.19" x2="7.19" y1="15.92" y2="9.68"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#767676"/></linearGradient><linearGradient id="h72-c" x1="1.92" x2="8.53" xlink:href="#h72-a" y1="3.97" y2="2.17"/><linearGradient gradientTransform="matrix(-1 0 0 1 16876.64 0)" id="h72-d" x1="16869.34" x2="16869.34" xlink:href="#h72-a" y1="13.79" y2="4.25"/><linearGradient id="h72-e" x1="3.22" x2="3.22" xlink:href="#h72-a" y1="10.17" y2=".97"/><linearGradient id="h72-f" x1="1.19" x2="1.19" xlink:href="#h72-a" y1="1.65" y2="8.28"/><linearGradient gradientUnits="userSpaceOnUse" id="h72-l" x1="2.38" x2="170.38" y1="22.2" y2="22.2"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h72-b" x1="2.38" x2="170.38" y1="21.54" y2="21.54"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h72-n" x1="170.38" x2="2.38" xlink:href="#h72-b" y1="22.79" y2="22.79"/><linearGradient id="h72-o" x1="2.38" x2="170.38" xlink:href="#h72-b" y1="27.54" y2="27.54"/><linearGradient id="h72-p" x1="170.38" x2="2.38" xlink:href="#h72-b" y1="28.79" y2="28.79"/><symbol id="h72-g" viewBox="0 0 14.38 15.07"><path d="m14.13 7.18.25 3.65c-1.79 2.7-4.39 4.24-6.86 4.24A9.28 9.28 0 0 1 0 10.48 14.93 14.93 0 0 1 .22 7c0 2.81 8.66 12 13.91.18Z" fill="url(#h72-a)"/><path d="M4.48 2.05c-3 0-4.26 3-4.26 5L0 4.68C-.14 2.05 2.49 0 4.79 0A3.13 3.13 0 0 1 8 3.14a3.32 3.32 0 0 1-2.8 3.25 1.32 1.32 0 0 0 .34-.2 2.31 2.31 0 0 0-1.06-4.14Z" fill="url(#h72-c)"/><path d="M14.22 8.46c-1.79 3.45-4.15 5.3-6.72 5.3C3.28 13.76.22 9.61.22 7c0-3 1.52-5.61 4.51-5.61 2.44 0 3 3.31.83 4.76C6.55 5.38 6.39 3 4.44 3 2.68 3 1.66 4.82 1.66 6.43s1.31 6 5.86 6S14.21 6 14.38 4Z" fill="url(#h72-d)"/></symbol><symbol id="h72-k" viewBox="0 0 4.76 10.27"><path d="m2.38 0-.71 5.58.71 4.68S4.76 7.6 4.76 5.13C4.76 2.92 3 1.72 2.38 0Z" fill="url(#h72-e)"/><path d="M2.38 0v10.26S0 7.6 0 5.13C0 2.92 1.73 1.72 2.38 0Z" fill="url(#h72-f)"/></symbol><symbol id="h72-m" viewBox="0 0 30.59 20.91"><use height="15.07" transform="translate(2.18 5.84)" width="14.38" xlink:href="#h72-g"/><use height="15.07" transform="matrix(-1 0 0 1 30.59 5.84)" width="14.38" xlink:href="#h72-g"/><path d="M14.71 9a1.84 1.84 0 0 1-.28-1 1.95 1.95 0 1 1 3.9 0 1.92 1.92 0 0 1-.27 1l-1.68 1Z" fill="url(#h72-h)"/><path d="M16.38 11.9a1.91 1.91 0 0 1-.71.73 2 2 0 1 1-1-3.64l1.67 1Z" fill="url(#h72-i)"/><path d="M16.38 11.9a1.95 1.95 0 1 0 2.67-2.65 2 2 0 0 0-1-.26l-1.68 1Z" fill="url(#h72-j)"/><use height="10.26" width="4.76" xlink:href="#h72-k"/></symbol><symbol id="h72-r" viewBox="0 0 170.59 29.41"><path d="M170.38 15.48c0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64 0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64 0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64 0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64 0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64 0 1.77-3.06 4.64-7.28 4.64a8.37 8.37 0 0 1-6.72-3.66 8.37 8.37 0 0 1-6.72 3.66c-4.22 0-7.28-2.87-7.28-4.64v13.43h168Z" fill="url(#h72-l)"/><use height="20.91" width="30.59" xlink:href="#h72-m"/><use height="20.91" transform="translate(28)" width="30.59" xlink:href="#h72-m"/><use height="20.91" transform="translate(56)" width="30.59" xlink:href="#h72-m"/><use height="20.91" transform="translate(84)" width="30.59" xlink:href="#h72-m"/><use height="20.91" transform="translate(112)" width="30.59" xlink:href="#h72-m"/><use height="20.91" transform="translate(140)" width="30.59" xlink:href="#h72-m"/><path d="M2.38 20.91h168v1.25h-168z" fill="url(#h72-b)"/><path d="M2.38 22.16h168v1.25h-168z" fill="url(#h72-n)"/><path d="M2.38 26.91h168v1.25h-168z" fill="url(#h72-o)"/><path d="M2.38 28.16h168v1.25h-168z" fill="url(#h72-p)"/></symbol><radialGradient cx="16876" cy="6.84" gradientTransform="matrix(-1 0 0 1 16892.38 0)" gradientUnits="userSpaceOnUse" id="h72-h" r="3.9"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><radialGradient cx="87.51" cy="9.77" gradientTransform="translate(-72.94)" id="h72-i" r="3.83" xlink:href="#h72-h"/><radialGradient cx="16497.6" cy="9.77" gradientTransform="matrix(-1 0 0 1 16515.8 0)" id="h72-j" r="3.83" xlink:href="#h72-h"/><clipPath id="h72-q"><path d="M160 72v75a50 50 0 0 1-100 0V72Z" fill="none"/></clipPath><filter id="h72-s"><feDropShadow dx=".5" dy="1.5" stdDeviation="0"/></filter></defs><g clip-path="url(#h72-q)"><use filter="url(#h72-s)" height="29.41" transform="matrix(-.64 .77 .77 .64 150.36 50.94)" width="170.59" xlink:href="#h72-r"/></g>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}