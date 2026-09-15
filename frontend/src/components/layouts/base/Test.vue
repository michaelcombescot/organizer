<script setup lang="ts">
    defineProps({
        id: {
            type: Number,
            required: true
        }
    })
</script>

<template>
    <div>
        Test Component {{ id }}
    </div>
</template>