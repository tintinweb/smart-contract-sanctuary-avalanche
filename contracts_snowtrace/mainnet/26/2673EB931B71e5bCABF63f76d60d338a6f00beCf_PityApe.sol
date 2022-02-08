//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PetAccessControl.sol";

contract PityApe is PetAccessControl {
    string constant public name = "Ape";

    function getPart(uint256 _partNumber) public view onlyOwner returns (string memory) {
        string[7] memory parts = [
            //head
            '<g id="head"><g id="head_ape"><path d="M579.503,248.325c-34.535,-0 -67.516,5.452 -88.399,37.539c-35.792,54.998 14.007,139.327 76.133,137.734" id="ApeColor"/><path d="M588.878,292.075c-88.571,-29.524 -106.647,80.749 -13.282,85.195" style="fill:#e7bb9d;"/><path d="M810.761,135.973c184.452,1.081 224.167,15.109 260.172,163.062c17.648,72.523 42.241,155.173 -37.668,207.053c-53.715,34.874 -164.235,75.686 -239.691,75.686c-83.435,-0 -191.829,-58.75 -233.258,-99.311c-38.94,-38.125 -25.255,-64.444 -16.479,-131.62c22.767,-174.252 61.567,-216.074 266.924,-214.87Z" id="ApeColor"/><path d="M1066.24,410.554c36.079,-9.284 69.177,-23.43 82.997,-60.119c23.687,-62.884 -49.354,-131.166 -113.861,-112.922" id="ApeColor"/><path d="M1051.86,273.07c29.193,-6.267 57.789,11.443 63.817,39.523c6.028,28.081 -12.78,55.967 -41.974,62.233c6.21,-13.751 9.304,-33.989 4.947,-54.284c-4.357,-20.296 -15.484,-37.481 -26.79,-47.472Z" style="fill:#e7bb9d;"/><path d="M598.052,367.487c-56.629,-102.787 32.363,-206.917 148.987,-200.515c19.662,1.079 49.009,11.611 55.253,10.223c6.422,-1.427 61.983,-12.686 80.428,-10.223c181.411,24.228 135.035,165.632 108.751,200.515c27.503,-0.567 53.496,54.642 0,102.331c-103.422,92.197 -293.148,71.65 -370.809,11.629c-46.066,-35.603 -75.323,-84.967 -22.61,-113.96Z" style="fill:#e7bb9d;"/><path d="M946.143,163.256c2.977,-14.886 10.233,-29.205 16.416,-42.944" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M984.543,188.856c0.284,0.285 2.514,-1.122 2.752,-1.248c7.362,-3.898 15.081,-6.84 22.976,-9.472" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M650.463,165.816c2.018,-2.018 -17.238,-17.28 -18.4,-18.176" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M836.063,154.296c-0,-13.416 12.829,-28.624 20.48,-38.432" style="fill:none;stroke:#000;stroke-width:24px;"/></g></g>',
            //body
            '<g id="belly"><g id="belly_ape"><path d="M857.916,453.453c-44.703,-3.734 -158.866,-0.956 -238.779,42.094c-44.503,23.975 -90.7,74.158 -103.735,124.124c-15.393,59.008 -65.845,126.041 -87.48,162.101c-24.254,40.422 -87.624,189.143 43.006,310.141c51.698,47.886 338.929,141.548 520.21,24.389c160.351,-103.632 66.848,-443.995 41.521,-518.421c-24.929,-73.254 -69.588,-135.645 -174.743,-144.428Z" id="ApeColor" style="stroke-width:22px;"/><path d="M820.034,459.492c-104.694,-13.44 -139.351,77.649 -164.183,135.457c-24.832,57.809 -198.066,285.84 24.96,341.865c238.249,59.849 230.094,-174.366 234.798,-317.821c2.043,-62.335 -15.038,-149.163 -95.575,-159.501Z" style="fill:#e7bb9d;"/><path d="M715.2,1124.16c-5.916,14.789 1.3,41.705 2.88,56.832" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M603.84,1055.04c-5.576,2.788 -9.665,19.328 -11.856,24.384" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M592.32,937.92c-0.267,-1.07 -3.473,1.919 -3.744,2.16c-8.916,7.925 -16.155,18.129 -22.128,28.368" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M638.4,966.72c-2.897,3.622 -4.995,8.002 -6.672,12.288" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M763.2,985.92c2.319,8.117 3.703,16.414 4.896,24.768" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M649.92,985.92c-1.41,2.819 -2.799,5.731 -3.888,8.688" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M603.84,989.76c-4.873,6.092 -7.284,16.524 -9.696,23.76" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M962.88,882.24c7.092,8.865 12.272,19.354 17.76,29.232" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M1007.04,895.68c1.028,2.569 2.344,5.042 3.456,7.584" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M1028.16,855.36c18.664,11.199 32.124,35.987 43.488,53.52" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M1055.04,936c6.419,6.419 11.543,14.261 16.224,21.984" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M479.04,765.12c-21.74,0 -42.792,3.807 -63.696,9.888" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M442.56,816.96c-21.375,0 -46.955,16.24 -64.368,26.688" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M567.36,713.28c-5.97,2.559 -11.512,8.607 -15.888,13.152" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M552,801.6c-6.796,-2.718 -30.034,26.512 -33.6,30.672" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M711.36,688.32c-7.481,9.619 -12.927,21.134 -18.144,32.064" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M793.92,676.8c1.388,3.471 1.088,8.251 1.392,11.904" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M863.04,657.6c5.829,20.402 6.183,43.06 7.584,64.08" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M838.08,797.76c2.163,7.571 3.654,15.197 4.8,22.992" style="fill:none;stroke:#000;stroke-width:14.53px;"/></g></g>',
            //right hand
            '<g id="paw_r"><g id="paw_r_ape"><path d="M374.586,622.809c-33.637,-51.435 -102.275,-2.744 -116.384,39.584c-8.259,24.777 27.034,87.002 50.368,91.839c29.34,6.083 95.713,-25.032 105.212,-58.908c7.741,-27.607 -25.45,-51.497 -39.196,-72.515Z" style="fill:#e7bb9d;stroke:#000;stroke-width:20px;"/><path d="M355.028,746.283c-21.023,4.833 -37.794,19.052 -49.125,32.335c1.024,5.53 -14.584,30.179 -30.379,30.552c-22.378,0.529 -13.741,-7.162 -11.847,-14.724c8.654,-34.555 23.551,-53.54 29.834,-65.028" style="fill:#e7bb9d;stroke:#000;stroke-width:20px;"/><path d="M284.989,692.656c-24.289,13.044 -48.618,32.015 -59.141,58.415c-2.868,7.194 -23.593,33.93 0,36.724c12.289,1.456 37.345,-9.24 38.11,-23.188c12.577,-13.836 34.941,-34.752 53.702,-40.366" style="fill:#e7bb9d;stroke:#000;stroke-width:20px;"/><path d="M282.23,634.013c-17.362,6.568 -59.918,34.551 -71.116,46.111c-18.682,19.286 -38.012,41.673 -18.58,51.912c11.237,5.921 30.449,2.566 38.505,-14.141c17.794,-8.81 41.359,-25.259 61.018,-25.355" style="fill:#e7bb9d;stroke:#000;stroke-width:20px;"/><path d="M361.434,617.401c-21.76,-39.323 -61.169,-47.216 -86.696,-37.08c-6.966,2.766 -67.862,-2.563 -40.138,25.223c10.854,10.877 21.206,13.423 47.999,16.173c8.368,9.763 5.427,23.975 41.275,31.495" style="fill:#e7bb9d;stroke:#000;stroke-width:20px;"/><path d="M306.07,668.276c8.076,20.19 16.863,35.088 32.302,51.573" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M255.994,671.641c0,1.569 1.116,3.609 1.744,4.992" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M279.674,720.281c0,1.027 0.862,2.178 1.36,3.008" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M301.754,752.281c0.521,0.694 1.361,1.314 2.08,1.776" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M552.518,528.444c-158.649,38.521 -211.522,23.871 -194.862,116.425c6.016,33.423 11.807,69.004 43.104,62.39c58.635,-12.391 79.433,5.303 137.724,0c79.679,-7.247 101.803,-200.125 14.034,-178.815Z" id="ApeColor"/><path d="M415.916,579.375c-3.59,-10.772 -18.694,-21.774 -27.504,-27.648" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M447.046,571.183c-5.399,-6.479 -7.823,-18.807 -10.035,-26.624" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M429.023,617.058c-1.77,-1.062 -3.89,-1.59 -5.755,-2.478" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M438.688,652.425c-4.171,2.502 -7.501,10.156 -9.81,14.151" style="fill:none;stroke:#000;stroke-width:14.53px;"/><path d="M374.55,592.207c-24.034,-2.94 -44.029,3.937 -38.158,22.724c3.538,11.323 41.858,2.98 41.658,3.107c-21.948,13.948 -40.033,16.505 -33.419,31.479c3.896,8.822 27.061,7.603 35.006,5.733c0.422,-0.1 -41.293,10.891 -29.831,32.459c4.674,8.796 32.57,-1.416 35.416,-2.926c0.843,-0.447 -31.451,16.712 -20.833,29.755c13.028,16.005 48.213,-14.908 56.334,-25.136" id="ApeColor" style="stroke-width:14.53px;"/></g></g>',
            //left hand
            '<g id="paw_l"><g id="paw_l_ape"><path d="M1021.4,581.217c64.287,-14.286 153.821,26.739 206.938,81.86c45.852,47.583 22.492,61.107 -24.614,112.973c-66.779,73.527 -110.799,15.15 -182.324,0c-137.632,-29.152 -61.531,-181.16 0,-194.833Z" id="ApeColor"/><path d="M1226.69,708.393c26.91,26.91 62.24,40.817 84.174,73.645c26.753,40.038 28.906,98.364 4.853,88.342c-23.409,-9.754 -111.08,-76.61 -125.266,-95.051" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M1277.02,798.54c13.942,18.999 30.499,40.195 29.29,89.612c-0.563,23.006 -8.764,37.81 -22.898,29.206c-24.356,-14.825 -28.655,-91.324 -65.313,-112.271" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M1245.89,810.153c23.474,46.948 28.969,67.965 26.843,103.377c-0.599,9.978 -14.094,34.242 -22.902,33.549c-29.625,-2.328 1.329,-78.777 -49.92,-89.027c-29.515,-5.903 16.834,41.811 -17.684,55.478c-15.913,6.3 -18.273,-18.119 -21.823,-25.458c-4.871,-10.066 -13.917,-18.776 -16.274,-29.616c-2.076,-9.55 -13.089,-40.134 -8.333,-48.303c17.175,-29.496 29.791,-36.086 54.514,-76.194" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M1163.43,857.02c1.67,-0 4.055,1.216 5.659,1.697" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1234.08,860.092c1.55,-0.886 3.121,-1.758 4.608,-2.749" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1277.09,841.66c0.517,-0.13 1.03,-0.236 1.536,-0.405" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1298.59,801.724c-0,-0.166 -0.009,-0.056 0.081,-0.324" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1126.38,793.894c8.638,23 25.966,35.299 43.51,16.432c10.573,-11.371 -17.374,-38.487 -17.138,-38.407c25.981,8.808 37.669,22.618 50.699,5.902c7.678,-9.848 -5.057,-29.044 -11.004,-34.564c-0.316,-0.292 32.183,27.827 49.998,2.072c7.265,-10.503 -17.581,-27.209 -20.624,-28.57c-0.902,-0.403 33.666,15.023 42.625,-3.749c10.992,-23.035 -39.961,-30.883 -55.086,-30.427" id="ApeColor" style="stroke-width:14.53px;"/><path d="M1084.61,767.913c2.03,5.076 4.025,10.114 6.48,15.024" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1163.33,646.953c15.509,-7.754 32.905,-12.69 49.44,-17.616" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1078.85,643.113c3.718,-5.204 11.995,-7.747 17.52,-10.224" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1076.93,606.633c1.348,-9.435 6.372,-19.078 10.56,-27.456" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1111.49,708.393c5.63,-1.608 11.864,-1.24 17.664,-1.44" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M1055.81,700.713c2.82,1.128 5.365,3.177 7.872,4.848" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/></g></g>',
            //left leg
            '<g id="leg_l"><g id="leg_l_ape"><path d="M1033.71,1132.86c51.967,0 93.921,30.961 113.808,73.815c16.635,35.845 14.204,55.654 0,64.713c-19.711,12.572 -56.059,-64.418 -75.811,-53.712c-41.257,22.363 -104.526,16.73 -124.733,-35.472c-4.296,-11.098 -4.584,-25.337 0.048,-36.384" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M1087.28,1183.44c12.171,6.086 39.249,38.221 45.296,71.055c6.41,34.805 16.254,67.139 -2.88,71.387c-20.007,4.442 -25.38,-17.693 -23.926,-31.755c-17.178,-48.41 -30.083,-63.277 -57.42,-71.942" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M1064.43,1215.85c21.369,14.246 63.258,69.876 29.472,121.546c-11.326,17.322 -31.191,4.589 -29.472,-29.08c-5.415,-23.409 -4.575,-48.636 -45.552,-51.368c-7.331,-0.489 -22.606,-2.23 -28.944,0c-34.133,12.01 13.322,35.763 0,59.232c-22.919,40.379 -37.829,-15.732 -45.249,-28.124c-29.669,-49.548 -18.202,-70.153 -0,-130.828" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M876.496,1192.52c68.882,46.6 69.831,-0.003 113.583,-24.96c41.005,-23.39 107.102,-13.936 80.639,-71.012c-30.687,-66.189 -85.84,-137.429 -176.932,-71.09c-72.512,52.807 -67.019,133.421 -17.29,167.062Z" id="ApeColor"/><path d="M1054.73,1094.2c32.814,16.335 31.532,38.95 28.723,46.011c-10.916,27.446 -48.826,-14.584 -49.375,-13.902c-0.261,0.323 24.498,39.883 13.932,48.311c-15.695,12.52 -40.32,-24.88 -40.728,-23.37c-0.465,1.721 23.069,45.603 11.706,55.776c-11.276,10.096 -43.445,-34.948 -43.151,-33.012c2.383,15.72 19.859,39.825 5.257,55.875c-14.432,15.864 -40.061,-38.831 -44.094,-44.202c-0.016,-0.022 0.05,-0.037 0.074,-0.03c1.959,0.529 13.335,47.748 -0.11,52.382c-12.632,4.354 -31.504,-24.476 -28.713,-43.948" id="ApeColor" style="stroke-width:15.27px;"/><path d="M912.753,1148.22c-1.318,4.615 -1.569,9.686 -1.776,14.448" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M935.793,1109.82c3.929,3.929 6.082,10.5 8.688,15.312" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M985.713,1100.22c4.46,0.496 8.88,2.513 13.008,4.128" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M966.129,1121.34c2.99,6.728 4.082,14.474 6.624,21.408" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M889.713,1171.26c-5.845,5.846 -7.026,18.959 -8.256,26.544" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/></g></g>',
            //right leg
            '<g id="leg_r"><g id="leg_r_ape"><path d="M313.308,975.175c-25.177,2.698 -44.07,7.355 -72.038,24.669c-25.496,15.783 -46.198,27.265 -56.279,69.703c-3.834,16.141 -28.891,41.034 6.482,34.591c19.975,-3.638 33.796,-42.207 60.856,-40.274c27.307,1.951 14.313,46.485 60.979,45.828c33.018,-0.465 79.006,-24.107 67.553,-59.959c-8.249,-25.824 -43.833,-63.08 -67.553,-74.558Z" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M267.843,1034.16c-12.709,-0 -51.857,31.141 -58.891,40.919c-6.429,8.939 -9.691,19.607 -12.226,30.198c-1.55,6.471 -18.088,32.846 -9.192,37.447c9.539,4.934 28.597,-4.169 31.587,-20.551c7.769,-10.49 38.059,-39.043 48.722,-47.094" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M278.902,1063.65c-3.452,1.726 -21.97,11.988 -24.392,14.869c-18.109,21.535 -27.958,28.738 -31.173,56.868c-0.85,7.438 -15.777,39.961 2.88,40.704c11.059,0.441 27.667,-4.967 28.293,-28.84c15.883,-30.773 53.515,-35.354 66.686,-33.587c13.172,1.768 9.718,25.372 11.115,40.507c-9.927,6.756 -4.062,28.22 5.376,29.007c14.862,1.238 24.291,-20.425 27.172,-31.674c7.27,-28.389 13.213,-77.932 -17.616,-94.942" style="fill:#e7bb9d;stroke:#05000e;stroke-width:20px;"/><path d="M445.214,1086.06c-50.885,8.801 -69.893,13.153 -98.455,-21.504c-37.061,-44.969 -56.247,-66.978 -41.472,-94.189c15.802,-29.101 71.312,-131.589 139.927,-61.8c40.289,40.978 91.978,161.585 0,177.493Z" id="ApeColor"/><path d="M315.612,971.904c-4.841,3.04 -38.959,25.298 -28.804,33.123c6.718,5.176 36.974,-4.991 37.256,-4.366c0.134,0.296 -30.113,23.641 -23.521,32.234c9.793,12.764 39.391,-9.027 39.35,-7.827c-0.046,1.368 -30.364,28.161 -23.551,38.215c6.761,9.978 44.475,-15.694 43.75,-14.342c-5.883,10.98 -26.281,24.659 -18.269,39.762c7.919,14.927 42.659,-19.315 47.318,-22.331c0.019,-0.012 -0.031,-0.038 -0.053,-0.039c-1.745,-0.059 -22.014,31.004 -12.98,38.427c4.64,3.813 29.726,-14.617 32.287,-29.53" id="ApeColor" style="stroke-width:15.27px;"/><path d="M329.471,961.796c-5.12,-5.12 -14.886,-7.077 -21.455,-9.167" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M374.691,984.406c-2.507,2.089 -4.334,5.529 -6.046,8.233" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M378.623,949.999c-3.308,-1.417 -7.059,-2.073 -10.568,-2.752" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M421.877,1033.56c-2.51,-1.255 -6.464,-0.792 -9.118,-0.615" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/><path d="M439.571,1074.85c2.437,3.046 -1.329,14.834 -1.917,18.211" style="fill:none;stroke:#05000e;stroke-width:15.27px;"/></g></g>',
            //add
            '<g id="add"><g id="add_ape"><path d="M1062.51,883.359c48.66,24.33 125.794,64.923 101.376,145.92c-18.318,60.764 -132.854,86.059 -174.72,48.845" style="fill:#e21809;stroke:#05000e;stroke-width:28px;"/><path d="M1110.51,988.959c0.55,0.549 5.001,-22.805 4.915,-24.73c-0.216,-4.859 -1.237,-9.613 -2.534,-14.285" style="fill:none;stroke:#05000e;stroke-width:20px;"/><path d="M1097.07,983.199c39.644,23.04 70.96,66.115 46.771,106.752c-18.136,30.468 -77.283,25.247 -108.902,21.734c-18.367,-2.041 -36.429,-8.88 -49.997,-21.734" style="fill:#e21809;stroke:#05000e;stroke-width:28px;"/><g><path d="M1223.18,270.288c0,65.204 -24.008,97.219 -47.983,131.348c-19.037,27.099 -38.091,55.343 -49.557,96.796c-11.752,42.491 -5.652,85.644 2.084,129.175c6.614,37.213 14.565,74.724 7.647,112.388c-6.786,36.949 -25.933,68.288 -46.102,99.258c-22.877,35.127 -68.662,82.036 -82.962,121.361c-4.483,12.328 1.886,25.975 14.214,30.458c12.327,4.483 22.809,-3.557 30.458,-14.214c26.888,-37.462 57.222,-79.574 78.121,-111.665c23.608,-36.249 45.079,-73.363 53.022,-116.611c7.954,-43.303 0.006,-86.507 -7.598,-129.293c-6.481,-36.467 -12.916,-72.589 -3.071,-108.185c12.448,-45.003 35.993,-71.654 55.966,-101.359c23.516,-34.977 43.295,-73.274 43.295,-139.457c-0,-13.117 -10.65,-23.766 -23.767,-23.766c-13.117,-0 -23.767,10.649 -23.767,23.766Z" id="ApeColor" style="stroke-width:18px;stroke-linecap:butt;stroke-miterlimit:2;"/><path d="M1174.61,473.463c9.379,0 22.927,10.266 31.32,13.8" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1243.61,260.463c-3.382,-5.073 0.202,-19.411 0.84,-24.84" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1222.35,351.888c-7.319,-14.637 -26.978,-25.115 -36.096,-39.552" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1227.15,308.688c-13.391,-13.39 -25.457,-28.284 -37.92,-42.528" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1253.55,270.288c7.958,-18.568 6.246,-20.632 20.787,-33.615" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1193.55,443.088c-0,0 4.036,-0.48 6.048,-0.768c17.749,-2.535 35.632,-5.089 53.472,-6.816" style="fill:none;stroke:#000;stroke-width:18px;"/><path d="M1131.15,553.488c-7.873,-4.723 -15.773,-9.415 -23.616,-14.208" style="fill:none;stroke:#000;stroke-width:18px;"/></g></g></g>'
        ];
        
        return parts[_partNumber];
    }

    function getColor(uint256 _colorId) public view onlyOwner returns (string memory, string memory) {
        string[10] memory colors = [
            'a16767',
            '822727',
            '805c3b',
            '790f09',
            '6e2533',
            '6b4466',
            '403a2a',
            '402a2a',
            '805a54',
            '51302b'
        ];

        return (colors[_colorId], "ApeColor");
    }
}