# sd-reviews

`sd-reviews` is a comprehensive and flexible reviews script for FiveM, allowing you to store, manage, and display user-submitted reviews for any business or location within your server.

## 🔔 Contact

Author: Samuel#0008  
Discord: [Join the Discord](https://discord.gg/FzPehMQaBQ)  
Store: [Click Here](https://fivem.samueldev.shop)

## 💾 Installation

1. Download the latest release from the [GitHub repository](https://github.com/Samuels-Development/sd_reviews/releases).
2. Extract the downloaded file and rename the folder to `sd-reviews`.
3. Place the `sd-reviews` folder into your server's `resources` directory.
4. Add `ensure sd-reviews` to your `server.cfg` so the resource starts with your server


## 📖 Dependencies
- qb-core, qbx_core or es_extended.
- [oxymsql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [sd_lib](https://github.com/Samuels-Development/sd_lib/releases)

## 📖 Usage

### Overview

`sd-reviews` lets you create and retrieve reviews for in-game businesses or other points of interest. It supports features like:

- Writing a new review
- Reading existing reviews
- Anonymous submissions (optional)
- Storing data in a MySQL database with live updates in memory for quick access

You can customize how many businesses exist, their locations, and how the script validates proximity or permissions before players can post or view reviews in the config.
