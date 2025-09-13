import * as admin from "firebase-admin";
import * as crypto from "crypto";
import axios from "axios";

import {onCall, HttpsError, onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {defineSecret} from "firebase-functions/params";

admin.initializeApp();
const db = admin.firestore();

const WEATHER_API_KEY = defineSecret("WEATHER_API_KEY");

async function fetchCityName(apiKey: string | undefined, cityId: string): Promise<string> {
  if (!apiKey) return "Unknown City";
  try {
    const resp = await axios.get("https://api.weatherapi.com/v1/forecast.json", {
      params: {key: apiKey, q: `id:${cityId}`, days: 1},
    });
    return resp?.data?.location?.name || "Unknown City";
  } catch (e) {
    console.error("fetchCityName error for cityId", cityId, e);
    return "Unknown City";
  }
}

function normalizeEmail(email?: string): string | null {
  if (!email) return null;
  return email.trim().toLowerCase();
}

// ========== onCall: requestSubscription ==========
export const requestSubscription = onCall(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (request) => {
    const payload = (request.data && request.data.email === undefined && request.data.data) ?
      request.data.data :
      request.data;

    const {email, cityId, cityName, isChangeRequest} = payload || {};
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail || !cityId) {
      throw new HttpsError("invalid-argument", "Email and cityId are required.");
    }

    console.log("requestSubscription", {email: normalizedEmail, cityId, isChangeRequest});

    if (isChangeRequest === true) {
      const subRef = db.collection("subscriptions").doc(normalizedEmail);
      const snap = await subRef.get();
      if (snap.exists) {
        const apiKey = WEATHER_API_KEY.value();
        let finalCityName = cityName;
        if (!finalCityName || finalCityName === "") {
          finalCityName = await fetchCityName(apiKey, cityId);
        }
        await subRef.update({
          cityId,
          cityName: finalCityName,
          updatedAt: admin.firestore.Timestamp.now(),
        });
        return {message: `Subscription updated. You will now receive weather updates for ${finalCityName}.`};
      }
      return {message: "No active subscription found. A verification email has been sent instead."};
    }

    const token = crypto.randomBytes(20).toString("hex");
    const expiresMs = Date.now() + 3600000;
    const apiKey = WEATHER_API_KEY.value();

    let finalCityName = cityName;
    if (!finalCityName || finalCityName === "") {
      finalCityName = await fetchCityName(apiKey, cityId);
    }

    await db.collection("pendingSubscriptions").doc(token).set({
      email: normalizedEmail,
      cityId,
      cityName: finalCityName || "Unknown City",
      expires: admin.firestore.Timestamp.fromMillis(expiresMs),
    });

    const region = "us-central1";
    const project = process.env.GCLOUD_PROJECT;
    const confirmationUrl = `https://${region}-${project}.cloudfunctions.net/confirmSubscription?token=${token}`;

    await db.collection("mail").add({
      to: normalizedEmail,
      message: {
        subject: "Confirm Your Weather Subscription",
        text: `Confirm your subscription: ${confirmationUrl}`,
        html: `<p>Please confirm your subscription:</p><a href="${confirmationUrl}">Confirm Subscription</a>`,
      },
    });

    return {message: "Verification email sent. Please check your inbox."};
  }
);

// ========== onCall: requestUnsubscription ==========
export const requestUnsubscription = onCall(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (request) => {
    const payload = (request.data && request.data.email === undefined && request.data.data) ?
      request.data.data :
      request.data;

    const {email} = payload || {};
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
      throw new HttpsError("invalid-argument", "Email is required.");
    }

    const subSnap = await db.collection("subscriptions").doc(normalizedEmail).get();
    if (!subSnap.exists) {
      return {message: "This email is not currently subscribed to any weather updates."};
    }

    const token = crypto.randomBytes(20).toString("hex");
    const expiresMs = Date.now() + 3600000;

    await db.collection("pendingUnsubscriptions").doc(token).set({
      email: normalizedEmail,
      expires: admin.firestore.Timestamp.fromMillis(expiresMs),
    });

    const region = "us-central1";
    const project = process.env.GCLOUD_PROJECT;
    const confirmationUrl = `https://${region}-${project}.cloudfunctions.net/confirmUnsubscription?token=${token}`;

    await db.collection("mail").add({
      to: normalizedEmail,
      message: {
        subject: "Confirm Unsubscription",
        text: `Confirm unsubscription: ${confirmationUrl}`,
        html: `<p>Click to confirm unsubscription:</p><a href="${confirmationUrl}">Confirm Unsubscription</a>`,
      },
    });

    return {message: "Unsubscription confirmation email sent."};
  }
);

// ========== onCall: checkSubscription ==========
export const checkSubscription = onCall(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (request) => {
    const payload = (request.data && request.data.email === undefined && request.data.data) ?
      request.data.data :
      request.data;

    const {email} = payload || {};
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
      throw new HttpsError("invalid-argument", "Email is required.");
    }

    const snap = await db.collection("subscriptions").doc(normalizedEmail).get();
    if (!snap.exists) return {exists: false};
    const data = snap.data() || {};
    return {
      exists: true,
      cityId: data.cityId,
      cityName: data.cityName || "Unknown City",
    };
  }
);

// ========== onRequest: confirmSubscription ==========
export const confirmSubscription = onRequest(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (req, res) => {
    const token = (req.query.token as string) || "";
    if (!token) {
      res.status(400).send("Invalid token");
      return;
    }

    const pendingRef = db.collection("pendingSubscriptions").doc(token);
    const snap = await pendingRef.get();
    if (!snap.exists) {
      res.status(404).send("Subscription request not found or expired");
      return;
    }

    const pending = snap.data();
    if (!pending) {
      res.status(500).send("Data error");
      return;
    }

    if (pending.expires.toMillis() < Date.now()) {
      res.status(410).send("Confirmation link expired");
      return;
    }

    const apiKey = WEATHER_API_KEY.value();
    let cityName = pending.cityName;
    if (!cityName || cityName === "") {
      cityName = await fetchCityName(apiKey, pending.cityId);
    }

    await db.collection("subscriptions").doc(pending.email).set({
      email: pending.email,
      cityId: pending.cityId,
      cityName: cityName || "Unknown City",
      createdAt: admin.firestore.Timestamp.now(),
    });

    await pendingRef.delete();

    res.send(`<html><body><h1>Subscription Confirmed</h1><p>Active for ${cityName}.</p></body></html>`);
  }
);

// ========== onRequest: confirmUnsubscription ==========
export const confirmUnsubscription = onRequest(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (req, res) => {
    const token = (req.query.token as string) || "";
    if (!token) {
      res.status(400).send("Invalid token");
      return;
    }

    const ref = db.collection("pendingUnsubscriptions").doc(token);
    const snap = await ref.get();
    if (!snap.exists) {
      res.status(404).send("Unsubscription request not found or expired");
      return;
    }

    const data = snap.data();
    if (!data) {
      res.status(500).send("Data error");
      return;
    }

    if (data.expires.toMillis() < Date.now()) {
      res.status(410).send("Confirmation link expired");
      return;
    }

    await db.collection("subscriptions").doc(data.email).delete();
    await ref.delete();

    res.send(`<html><body><h1>Unsubscription Confirmed</h1><p>${data.email} removed.</p></body></html>`);
  }
);

// ========== onCall: searchCities ==========
export const searchCities = onCall(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (request) => {
    const payload = (request.data && request.data.query === undefined && request.data.data) ?
      request.data.data :
      request.data;

    const {query} = payload || {};

    if (!query || typeof query !== "string") {
      // Return default cities for empty query
      return [
        {id: 2717933, name: "Ha Noi", region: "", country: "Vietnam"},
        {id: 2718413, name: "Ho Chi Minh City", region: "", country: "Vietnam"},
      ];
    }

    const apiKey = WEATHER_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError("internal", "API key not configured");
    }

    try {
      const response = await axios.get("https://api.weatherapi.com/v1/search.json", {
        params: {key: apiKey, q: query},
      });

      return response.data || [];
    } catch (e) {
      console.error("searchCities error:", e);
      return [];
    }
  }
);

// ========== onCall: getWeatherData ==========
export const getWeatherData = onCall(
  {region: "us-central1", secrets: [WEATHER_API_KEY]},
  async (request) => {
    const payload = (request.data && request.data.cityId === undefined && request.data.data) ?
      request.data.data :
      request.data;

    const {cityId, days = 4} = payload || {};

    if (!cityId) {
      throw new HttpsError("invalid-argument", "City ID is required");
    }

    const apiKey = WEATHER_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError("internal", "API key not configured");
    }

    try {
      const response = await axios.get("https://api.weatherapi.com/v1/forecast.json", {
        params: {key: apiKey, q: `id:${cityId}`, days: Math.min(days, 10)},
      });

      return response.data;
    } catch (e) {
      console.error("getWeatherData error:", e);
      throw new HttpsError("internal", "Failed to fetch weather data");
    }
  }
);

// ========== onSchedule: sendDailyWeatherUpdates ==========
export const sendDailyWeatherUpdates = onSchedule(
  {
    region: "us-central1",
    schedule: "20 7 * * *",
    timeZone: "Asia/Ho_Chi_Minh",
    secrets: [WEATHER_API_KEY],
  },
  async () => {
    console.log("sendDailyWeatherUpdates start");
    const apiKey = WEATHER_API_KEY.value();
    console.log("Secret present:", apiKey ? "yes" : "no");

    if (!apiKey) {
      console.error("Missing WEATHER_API_KEY");
      return;
    }

    const subsSnap = await db.collection("subscriptions").get();
    if (subsSnap.empty) {
      console.log("No subscriptions");
      return;
    }

    await Promise.all(
      subsSnap.docs.map(async (docSnap) => {
        const sub = docSnap.data();
        try {
          const resp = await axios.get("https://api.weatherapi.com/v1/forecast.json", {
            params: {key: apiKey, q: `id:${sub.cityId}`, days: 1},
          });
          const w = resp.data;
          const current = w.current;
          const forecast = w.forecast.forecastday[0];
          const location = w.location;

          if (!sub.cityName || sub.cityName === "") {
            await docSnap.ref.update({
              cityName: location.name,
              updatedAt: admin.firestore.Timestamp.now(),
            });
          }

          await db.collection("mail").add({
            to: sub.email,
            message: {
              subject: `Daily Weather Update for ${location.name}`,
              html: `<h2>${location.name}</h2>
                     <p>${current.condition.text}, ${current.temp_c}°C (feels ${current.feelslike_c}°C)</p>
                     <p>Humidity: ${current.humidity}% | Wind: ${current.wind_kph} km/h ${current.wind_dir}</p>
                     <h3>Today</h3>
                     <p>Min: ${forecast.day.mintemp_c}°C | Max: ${forecast.day.maxtemp_c}°C</p>
                     <p>${forecast.day.condition.text} | Chance of rain: ${forecast.day.daily_chance_of_rain}%</p>`,
            },
          });
          console.log("Email queued for", sub.email);
        } catch (e) {
          console.error("Weather email failed for", sub.email, e);
        }
      })
    );

    console.log("sendDailyWeatherUpdates done");
  }
);
