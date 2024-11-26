/**
 * To run this script:
 * 1. Ensure Chrome is running with remote debugging enabled:
 *    google-chrome --remote-debugging-port=9222
 * 2. Open the necessary browser tabs:
 *    - Google Doc with the required content.
 *    - Remix IDE for Ethereum interactions.
 * 3. Start this script on your local machine:
 *    node google_doc_to_remix.js
 */

const express = require('express');
const puppeteer = require('puppeteer');

// Custom delay function
const delay = (time) => new Promise(resolve => setTimeout(resolve, time));

const app = express();
app.use(express.json()); // Middleware to parse JSON bodies

app.post('/trigger', async (req, res) => {
    try {
        console.log("Trigger received. Starting automation...");

        // Connect to Chrome instance
        const browser = await puppeteer.connect({
            browserURL: 'http://localhost:9222', // Ensure Chrome is running with remote debugging enabled
        });

        // Step 1: Locate the Google Doc tab
        const pages = await browser.pages();
        const googleDocPage = pages.find(page => page.url().includes('docs.google.com'));

        if (!googleDocPage) {
            res.status(400).send("Google Doc is not open. Please open the Google Doc in a browser tab.");
            console.log("Google Doc not found. Exiting.");
            await browser.disconnect();
            return;
        }

        console.log("Google Doc found. Reading content...");
        const docText = await googleDocPage.evaluate(() => document.body.innerText);

        if (!docText.includes("the ship has arrived")) {
            res.status(200).send("Phrase not found in Google Doc. Exiting.");
            console.log("Necessary phrase not found.");
            await browser.disconnect();
            return;
        }

        console.log("Phrase detected: 'the ship has arrived'");

        // Step 2: Locate the Remix tab
        const remixPage = pages.find(page => page.url().includes('remix.ethereum.org'));

        if (!remixPage) {
            res.status(400).send("Remix IDE is not open. Please open Remix in a browser tab.");
            console.log("Remix IDE tab not found. Exiting.");
            await browser.disconnect();
            return;
        }

        console.log("Remix tab found. Interacting with elements...");
        await remixPage.bringToFront();

        // Select address
        await remixPage.waitForSelector('select#txorigin');
        await remixPage.select('select#txorigin', '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db');
        console.log("Address selected.");

        // Click the triggerSwap button
        const triggerSwapButtonSelector = 'button[data-id="triggerSwap - transact (not payable)"]';
        await remixPage.waitForSelector(triggerSwapButtonSelector, { visible: true });
        await remixPage.$eval(triggerSwapButtonSelector, button => button.click());
        console.log("triggerSwap executed successfully.");

        await browser.disconnect();
        res.status(200).send("Automation complete. TriggerSwap executed.");
    } catch (error) {
        console.error("Error during automation:", error);
        res.status(500).send(`Error: ${error.message}`);
    }
});

const PORT = 4000;
app.listen(PORT, () => {
    console.log(`Server running locally on http://localhost:${PORT}`);
});
