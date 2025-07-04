package com.example.maintenance_app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.filament.Engine
import com.google.ar.core.Anchor
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.TrackingFailureReason
import io.github.sceneview.ar.ARScene
import io.github.sceneview.ar.arcore.createAnchorOrNull
import io.github.sceneview.ar.arcore.getUpdatedPlanes
import io.github.sceneview.ar.arcore.isValid
import io.github.sceneview.ar.getDescription
import io.github.sceneview.ar.node.AnchorNode
import io.github.sceneview.ar.rememberARCameraNode
import io.github.sceneview.loaders.MaterialLoader
import io.github.sceneview.loaders.ModelLoader
import io.github.sceneview.node.CubeNode
import io.github.sceneview.node.ModelNode
import io.github.sceneview.rememberCollisionSystem
import io.github.sceneview.rememberEngine
import io.github.sceneview.rememberMaterialLoader
import io.github.sceneview.rememberModelLoader
import io.github.sceneview.rememberNodes
import io.github.sceneview.rememberOnGestureListener
import io.github.sceneview.rememberView
import androidx.compose.runtime.DisposableEffect
import timber.log.Timber

class ArModelViewerActivity : ComponentActivity() {

    private var modelFile: String = "models/damaged_helmet.glb"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        modelFile = intent.getStringExtra("model_file") ?: "models/damaged_helmet.glb"

        setContent {
            Box(
                modifier = Modifier.fillMaxSize(),
            ) {
                val engine = rememberEngine()
                val modelLoader = rememberModelLoader(engine)
                val materialLoader = rememberMaterialLoader(engine)
                val cameraNode = rememberARCameraNode(engine)
                val childNodes = rememberNodes()
                val view = rememberView(engine)
                val collisionSystem = rememberCollisionSystem(view)

                var planeRenderer by remember { mutableStateOf(true) }
                var trackingFailureReason by remember { mutableStateOf<TrackingFailureReason?>(null) }
                var frame by remember { mutableStateOf<Frame?>(null) }

                // CLEANUP nodes UNIQUEMENT ici
                DisposableEffect(Unit) {
                    onDispose {
                        childNodes.forEach {
                            try {
                                it.destroy()
                            } catch (e: Exception) {
                                Timber.tag("AR_CLEANUP").e(e, "Error destroying node: $it")
                            }
                        }
                    }
                }

                ARScene(
                    modifier = Modifier.fillMaxSize(),
                    childNodes = childNodes,
                    engine = engine,
                    view = view,
                    modelLoader = modelLoader,
                    collisionSystem = collisionSystem,
                    sessionConfiguration = { session, config ->
                        config.depthMode = if (session.isDepthModeSupported(Config.DepthMode.AUTOMATIC))
                            Config.DepthMode.AUTOMATIC else Config.DepthMode.DISABLED
                        config.instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
                        config.lightEstimationMode = Config.LightEstimationMode.ENVIRONMENTAL_HDR
                    },
                    cameraNode = cameraNode,
                    planeRenderer = planeRenderer,
                    onTrackingFailureChanged = { trackingFailureReason = it },
                    onSessionUpdated = { session, updatedFrame ->
                        frame = updatedFrame
                        if (childNodes.isEmpty()) {
                            updatedFrame.getUpdatedPlanes()
                                .firstOrNull { it.type == Plane.Type.HORIZONTAL_UPWARD_FACING }
                                ?.let { it.createAnchorOrNull(it.centerPose) }?.let { anchor ->
                                    childNodes += createAnchorNode(
                                        engine = engine,
                                        modelLoader = modelLoader,
                                        materialLoader = materialLoader,
                                        anchor = anchor
                                    )
                                }
                        }
                    },
                    onGestureListener = rememberOnGestureListener(
                        onSingleTapConfirmed = { motionEvent, node ->
                            if (node == null) {
                                val hitResults = frame?.hitTest(motionEvent.x, motionEvent.y)
                                hitResults?.firstOrNull {
                                    it.isValid(depthPoint = false, point = false)
                                }?.createAnchorOrNull()
                                    ?.let { anchor ->
                                        planeRenderer = false
                                        childNodes += createAnchorNode(
                                            engine = engine,
                                            modelLoader = modelLoader,
                                            materialLoader = materialLoader,
                                            anchor = anchor
                                        )
                                    }
                            }
                        })
                )

                Text(
                    modifier = Modifier
                        .systemBarsPadding()
                        .fillMaxWidth()
                        .align(Alignment.TopCenter)
                        .padding(top = 16.dp, start = 32.dp, end = 32.dp),
                    textAlign = TextAlign.Center,
                    fontSize = 28.sp,
                    color = Color.White,
                    text = trackingFailureReason?.let {
                        it.getDescription(LocalContext.current)
                    } ?: if (childNodes.isEmpty()) {
                        "Point your phone down at an empty space, and move it around slowly"
                    } else {
                        "Tap anywhere to add model"
                    }
                )
            }
        }
    }

    private fun createAnchorNode(
        engine: Engine,
        modelLoader: ModelLoader,
        materialLoader: MaterialLoader,
        anchor: Anchor
    ): AnchorNode {
        val anchorNode = AnchorNode(engine = engine, anchor = anchor)
        val modelNode = ModelNode(
            modelInstance = modelLoader.createModelInstance(modelFile),
            scaleToUnits = 0.5f
        ).apply {
            isEditable = true
            editableScaleRange = 0.2f..0.75f
        }
        val boundingBoxNode = CubeNode(
            engine,
            size = modelNode.extents,
            center = modelNode.center,
            materialInstance = materialLoader.createColorInstance(Color.White.copy(alpha = 0.5f))
        ).apply { isVisible = false }
        modelNode.addChildNode(boundingBoxNode)
        anchorNode.addChildNode(modelNode)
        listOf(modelNode, anchorNode).forEach {
            it.onEditingChanged = { editingTransforms ->
                boundingBoxNode.isVisible = editingTransforms.isNotEmpty()
            }
        }
        return anchorNode
    }
}