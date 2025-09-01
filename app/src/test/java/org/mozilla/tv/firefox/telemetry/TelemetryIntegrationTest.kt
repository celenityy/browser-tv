/* -*- Mode: Java; c-basic-offset: 4; tab-width: 20; indent-tabs-mode: nil; -*-
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@file:Suppress("DEPRECATION")

package org.mozilla.tv.firefox.telemetry

import android.app.Application
import androidx.test.core.app.ApplicationProvider
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.spy
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mozilla.tv.firefox.utils.anyNonNull
import org.mozilla.telemetry.Telemetry
import org.mozilla.telemetry.TelemetryHolder
import org.mozilla.tv.firefox.helpers.FirefoxRobolectricTestRunner

@RunWith(FirefoxRobolectricTestRunner::class)
class TelemetryIntegrationTest {
    private lateinit var appContext: Application
    private lateinit var telemetryIntegration: TelemetryIntegration
    private lateinit var telemetrySpy: Telemetry

    @Before
    fun setup() {
        appContext = ApplicationProvider.getApplicationContext()
        val telemetry = TelemetryFactory.createTelemetry(appContext)
        telemetrySpy = spy(telemetry)
        TelemetryHolder.set(telemetrySpy)
        telemetryIntegration = TestTelemetryIntegration()
    }

    @Test
    fun `WHEN startSession and stopSession are called on TelemetryWrapper THEN associated Telemetry methods should be called`() {
        telemetryIntegration.startSession(appContext)
        verify(telemetrySpy, times(1)).recordSessionStart()
        verify(telemetrySpy, times(0)).recordSessionEnd(any())

        telemetryIntegration.stopSession(appContext)
        verify(telemetrySpy, times(1)).recordSessionStart()
        verify(telemetrySpy, times(1)).recordSessionEnd(any())
    }
}

/**
 * Allows us to pass a non-default value for testing
 * purposes
 */
private class TestTelemetryIntegration() : TelemetryIntegration()
