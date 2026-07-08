package com.reelscounter.app

/**
 * Lightweight in-process pub/sub so the AccessibilityService (which may run
 * independently of the Flutter UI) can notify MainActivity whenever the
 * count changes, without needing IPC since everything runs in one process.
 */
object CounterBus {
    private val listeners = mutableListOf<(Int) -> Unit>()

    @Volatile
    var currentCount: Int = 0
        private set

    @Volatile
    var trackingEnabled: Boolean = true

    fun addListener(listener: (Int) -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: (Int) -> Unit) {
        listeners.remove(listener)
    }

    fun increment() {
        if (!trackingEnabled) return
        currentCount += 1
        notifyAll(currentCount)
    }

    fun setCount(count: Int) {
        currentCount = count
        notifyAll(currentCount)
    }

    private fun notifyAll(count: Int) {
        listeners.toList().forEach { it(count) }
    }
}
