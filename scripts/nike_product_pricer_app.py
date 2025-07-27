import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import matplotlib.pyplot as plt
import seaborn as sns
try:
    from wordcloud import WordCloud
    WORDCLOUD_AVAILABLE = True
except ImportError:
    WORDCLOUD_AVAILABLE = False
import warnings
warnings.filterwarnings('ignore')

from snowflake.snowpark.context import get_active_session
import snowflake.snowpark.functions as F
from snowflake.cortex import complete

# Page configuration
st.set_page_config(
    page_title="Nike Product Pricer App",
    page_icon="👟",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 1rem;
    }
    .product-card {
        border: 2px solid #e1e5e9;
        border-radius: 10px;
        padding: 10px;
        margin: 10px;
        text-align: center;
        background-color: #f8f9fa;
    }
    .selected-card {
        border: 3px solid #007bff;
        background-color: #e3f2fd;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 10px;
        border: 1px solid #e1e5e9;
        margin: 0.5rem 0;
    }
    .sentiment-positive { color: #28a745; font-weight: bold; }
    .sentiment-negative { color: #dc3545; font-weight: bold; }
    .sentiment-neutral { color: #ffc107; font-weight: bold; }
</style>
""", unsafe_allow_html=True)

def get_session():
    """Get active Snowflake session"""
    try:
        return get_active_session()
    except:
        st.error("Unable to connect to Snowflake. Please ensure you're running in a Snowflake environment.")
        st.stop()

def load_pricing_data():
    """Load pricing data from Snowflake"""
    session = get_session()
    try:
        # Load pricing data
        pricing_df = session.table("nike_po_prod.analytics.menu_item_aggregate_dt").toPandas()
        return pricing_df
    except Exception as e:
        st.error(f"Error loading pricing data: {e}")
        return pd.DataFrame()

def load_review_data():
    """Load review and sentiment data"""
    session = get_session()
    try:
        # Load review sentiment data
        sentiment_df = session.sql("""
            SELECT 
                product_name,
                brand_name,
                avg_sentiment,
                avg_rating,
                total_reviews,
                recommendation_rate,
                sentiment_category
            FROM nike_reviews.analytics.product_sentiment_pricing_v
        """).toPandas()
        
        # Load individual reviews for word cloud
        reviews_df = session.sql("""
            SELECT 
                product_name,
                brand_name,
                translated_review,
                sentiment_score,
                rating
            FROM nike_reviews.analytics.product_reviews_v
            WHERE translated_review IS NOT NULL
        """).toPandas()
        
        return sentiment_df, reviews_df
    except Exception as e:
        st.warning(f"Review data not available: {e}")
        return pd.DataFrame(), pd.DataFrame()

def get_product_image_url(product_name):
    """Get product image URL"""
    # In a real scenario, this would query the product database
    # For now, we'll use a mapping
    image_mapping = {
        "Air Force 1 '07": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/b7d9211c-26e7-431a-ac24-b72b2fd95d97/air-force-1-07-mens-shoes-jBrhbr.png",
        "Air Max 90": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/00375837-849f-4f17-ba24-d201d27be49b/air-force-1-high-07-mens-shoes-Sk50TJ.png",
        "Air Zoom Pegasus 40": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/bc7e88e7-7db0-4c7b-82dc-f5a49cd5d04e/air-jordan-1-low-mens-shoes-0LXhbn.png",
        "Metcon 9": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/3cc96f43-47b6-43cb-951d-d8f73bb2f912/air-force-1-lv8-big-kids-shoes-1Irpw1.png",
        "Air Jordan 1 Low": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/bc7e88e7-7db0-4c7b-82dc-f5a49cd5d04e/air-jordan-1-low-mens-shoes-0LXhbn.png",
        "Tech Fleece Hoodie": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/placeholder-hoodie.png",
        "Dunk Low": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/dunk-low-retro-mens-shoes-placeholder.png"
    }
    return image_mapping.get(product_name, "https://via.placeholder.com/200x200?text=Nike+Product")

def forecast_demand_and_price(product_name, brand_name, day_of_week, current_price):
    """Forecast demand and recommend price using ML model simulation"""
    # Simulate ML model prediction (in real scenario, this would call actual ML model)
    np.random.seed(hash(product_name + str(day_of_week)) % 2**32)
    
    # Base demand factors
    weekend_multiplier = 1.3 if day_of_week in ['Saturday', 'Sunday'] else 1.0
    brand_popularity = {
        'Nike Running': 1.2, 'Nike Jordan': 1.4, 'Nike Sportswear': 1.1,
        'Nike Training': 1.0, 'Nike SB': 0.9, 'Nike Tech': 1.1
    }
    
    brand_factor = brand_popularity.get(brand_name, 1.0)
    
    # Current demand estimation
    base_demand = np.random.normal(100, 20) * weekend_multiplier * brand_factor
    base_demand = max(base_demand, 10)  # Minimum demand
    
    # Price elasticity (how demand changes with price)
    price_elasticity = -1.2  # Typical elasticity for athletic footwear
    
    # Optimal price calculation (simplified)
    optimal_price = current_price * (1 + np.random.uniform(-0.15, 0.10))  # ±15% range
    
    # Forecasted demand at optimal price
    price_change_ratio = optimal_price / current_price
    demand_change = (price_change_ratio ** price_elasticity)
    forecasted_demand = base_demand * demand_change
    
    return {
        'current_demand': int(base_demand),
        'forecasted_demand': int(forecasted_demand),
        'recommended_price': round(optimal_price, 2),
        'price_change_pct': round((optimal_price - current_price) / current_price * 100, 1)
    }

def calculate_margin(recommended_price, cost):
    """Calculate expected margin"""
    margin = recommended_price - cost
    margin_pct = (margin / recommended_price) * 100 if recommended_price > 0 else 0
    return margin, margin_pct

def create_sentiment_wordcloud(reviews_text):
    """Create word cloud from reviews"""
    if not reviews_text or not WORDCLOUD_AVAILABLE:
        return None
    
    try:
        # Remove common words and generate word cloud
        stopwords_custom = {'nike', 'shoe', 'shoes', 'product', 'item', 'brand', 'buy', 'bought', 'purchase'}
        
        wordcloud = WordCloud(
            width=400, 
            height=200, 
            background_color='white',
            colormap='viridis',
            stopwords=stopwords_custom,
            max_words=50
        ).generate(reviews_text)
        
        fig, ax = plt.subplots(figsize=(8, 4))
        ax.imshow(wordcloud, interpolation='bilinear')
        ax.axis('off')
        
        return fig
    except Exception as e:
        st.warning(f"Could not generate word cloud: {e}")
        return None

def create_sentiment_charts(sentiment_data, reviews_data, product_name):
    """Create sentiment visualization charts"""
    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=(
            "Sentiment Distribution", 
            "Rating Distribution",
            "Sentiment Over Time",
            "Review Sources"
        ),
        specs=[[{"type": "pie"}, {"type": "histogram"}],
               [{"type": "scatter"}, {"type": "pie"}]]
    )
    
    # Sentiment distribution pie chart
    if not sentiment_data.empty:
        sentiment_counts = sentiment_data['sentiment_category'].value_counts()
        colors = {'POSITIVE': '#28a745', 'NEGATIVE': '#dc3545', 'NEUTRAL': '#ffc107'}
        
        fig.add_trace(
            go.Pie(
                labels=sentiment_counts.index,
                values=sentiment_counts.values,
                marker_colors=[colors.get(label, '#6c757d') for label in sentiment_counts.index],
                name="Sentiment"
            ),
            row=1, col=1
        )
    
    # Rating distribution
    if not reviews_data.empty:
        product_reviews = reviews_data[reviews_data['product_name'] == product_name]
        if not product_reviews.empty:
            fig.add_trace(
                go.Histogram(
                    x=product_reviews['rating'],
                    nbinsx=5,
                    marker_color='#1f77b4',
                    name="Ratings"
                ),
                row=1, col=2
            )
    
    # Update layout
    fig.update_layout(
        height=600,
        showlegend=True,
        title_text="Sentiment Analysis Dashboard"
    )
    
    return fig

def main():
    # App header
    st.markdown('<h1 class="main-header">👟 Nike Product Pricer App</h1>', unsafe_allow_html=True)
    st.markdown("### AI-Powered Price Optimization with Customer Sentiment Analysis")
    st.markdown("---")
    
    # Load data
    with st.spinner("Loading product data..."):
        pricing_df = load_pricing_data()
        sentiment_df, reviews_df = load_review_data()
    
    if pricing_df.empty:
        st.error("No pricing data available. Please check your Snowflake connection.")
        return
    
    # Sidebar for inputs
    with st.sidebar:
        st.header("🎯 Product Selection")
        
        # Step 1: Brand Selection
        st.subheader("1. Select Brand Line")
        available_brands = sorted(pricing_df['TRUCK_BRAND_NAME'].unique()) if 'TRUCK_BRAND_NAME' in pricing_df.columns else []
        selected_brand = st.selectbox(
            "Choose Nike Brand Line:",
            available_brands,
            help="Select the Nike product line you want to analyze"
        )
        
        if selected_brand:
            # Step 2: Product Selection with Images
            st.subheader("2. Select Product")
            
            # Filter products for selected brand
            brand_products = pricing_df[pricing_df['TRUCK_BRAND_NAME'] == selected_brand]['MENU_ITEM_NAME'].unique()
            
            # Create product selection with images
            st.write("Choose a product:")
            
            # Create a visual product selector
            product_options = []
            for product in brand_products:
                image_url = get_product_image_url(product)
                product_options.append({
                    'name': product,
                    'image': image_url
                })
            
            # Display products in a grid with selection
            cols = st.columns(2)
            selected_product = None
            
            for i, product_info in enumerate(product_options):
                with cols[i % 2]:
                    # Create a container for each product
                    container = st.container()
                    with container:
                        col_img, col_text = st.columns([1, 2])
                        with col_img:
                            st.image(product_info['image'], width=100)
                        with col_text:
                            st.write(f"**{product_info['name']}**")
                            if st.button(f"Select", key=f"select_{i}", use_container_width=True):
                                selected_product = product_info['name']
                                st.session_state.selected_product_temp = product_info['name']
            
            # Use session state to persist selection
            if hasattr(st.session_state, 'selected_product_temp'):
                selected_product = st.session_state.selected_product_temp
                st.success(f"✅ Selected: **{selected_product}**")
            
            # Step 3: Day of Week Selection
            if selected_product:
                st.subheader("3. Select Day of Week")
                days_of_week = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                selected_day = st.selectbox(
                    "Day for price forecasting:",
                    days_of_week,
                    help="Select the day of week for demand forecasting"
                )
                
                # Submit button
                analyze_button = st.button("🚀 Analyze Product & Price", type="primary", use_container_width=True)
                
                if analyze_button:
                    st.session_state.analysis_ready = True
                    st.session_state.selected_product = selected_product
                    st.session_state.selected_brand = selected_brand
                    st.session_state.selected_day = selected_day
    
    # Main content area
    if hasattr(st.session_state, 'analysis_ready') and st.session_state.analysis_ready:
        
        product = st.session_state.selected_product
        brand = st.session_state.selected_brand
        day = st.session_state.selected_day
        
        # Get product data
        product_data = pricing_df[
            (pricing_df['TRUCK_BRAND_NAME'] == brand) & 
            (pricing_df['MENU_ITEM_NAME'] == product)
        ]
        
        if not product_data.empty:
            current_price = float(product_data['PRICE'].iloc[0]) if 'PRICE' in product_data.columns else 150.0
            cost = float(product_data['COST_OF_GOODS_USD'].iloc[0]) if 'COST_OF_GOODS_USD' in product_data.columns else current_price * 0.6
        else:
            current_price = 150.0  # Default price
            cost = 90.0  # Default cost
        
        # Results Display
        st.header(f"📊 Analysis Results for {product}")
        
        # Row 1: Product Overview
        col1, col2, col3 = st.columns([1, 2, 1])
        
        with col1:
            st.subheader("Selected Product")
            image_url = get_product_image_url(product)
            st.image(image_url, width=200, caption=f"{brand} - {product}")
        
        with col2:
            st.subheader("Product Information")
            st.metric("Current Price", f"${current_price:.2f}")
            st.metric("Product Cost", f"${cost:.2f}")
            st.metric("Analysis Day", day)
            
            # Get forecast
            forecast = forecast_demand_and_price(product, brand, day, current_price)
            margin, margin_pct = calculate_margin(forecast['recommended_price'], cost)
            
            st.metric(
                "Current Margin", 
                f"${current_price - cost:.2f} ({((current_price - cost)/current_price*100):.1f}%)"
            )
        
        with col3:
            st.subheader("Price Recommendation")
            price_change = forecast['price_change_pct']
            st.metric(
                "Recommended Price", 
                f"${forecast['recommended_price']:.2f}",
                delta=f"{price_change:+.1f}%"
            )
            st.metric(
                "Forecasted Demand", 
                f"{forecast['forecasted_demand']} units",
                delta=f"{forecast['forecasted_demand'] - forecast['current_demand']:+d} units"
            )
            st.metric(
                "Expected Margin", 
                f"${margin:.2f} ({margin_pct:.1f}%)"
            )
        
        st.markdown("---")
        
        # Row 2: Sentiment Analysis
        st.header("💭 Customer Sentiment Analysis")
        
        # Get sentiment data for this product
        product_sentiment = sentiment_df[
            (sentiment_df['product_name'] == product) & 
            (sentiment_df['brand_name'] == brand)
        ] if not sentiment_df.empty else pd.DataFrame()
        
        product_reviews = reviews_df[
            (reviews_df['product_name'] == product) & 
            (reviews_df['brand_name'] == brand)
        ] if not reviews_df.empty else pd.DataFrame()
        
        if not product_sentiment.empty:
            col1, col2 = st.columns([1, 1])
            
            with col1:
                st.subheader("Sentiment Overview")
                
                sentiment_score = product_sentiment['avg_sentiment'].iloc[0]
                avg_rating = product_sentiment['avg_rating'].iloc[0]
                total_reviews = product_sentiment['total_reviews'].iloc[0]
                recommendation_rate = product_sentiment['recommendation_rate'].iloc[0]
                
                # Sentiment indicators
                if sentiment_score > 0.3:
                    sentiment_class = "sentiment-positive"
                    sentiment_emoji = "😊"
                elif sentiment_score < -0.3:
                    sentiment_class = "sentiment-negative"
                    sentiment_emoji = "😞"
                else:
                    sentiment_class = "sentiment-neutral"
                    sentiment_emoji = "😐"
                
                st.markdown(f"""
                <div class="metric-card">
                    <h4>{sentiment_emoji} Overall Sentiment: <span class="{sentiment_class}">{product_sentiment['sentiment_category'].iloc[0]}</span></h4>
                    <p><strong>Average Rating:</strong> {avg_rating:.1f}/5.0 ⭐</p>
                    <p><strong>Total Reviews:</strong> {total_reviews}</p>
                    <p><strong>Recommendation Rate:</strong> {recommendation_rate:.1f}%</p>
                    <p><strong>Sentiment Score:</strong> {sentiment_score:.3f}</p>
                </div>
                """, unsafe_allow_html=True)
                
                # Word cloud
                if not product_reviews.empty:
                    st.subheader("Customer Review Word Cloud")
                    reviews_text = ' '.join(product_reviews['translated_review'].dropna().tolist())
                    wordcloud_fig = create_sentiment_wordcloud(reviews_text)
                    if wordcloud_fig:
                        st.pyplot(wordcloud_fig)
                    elif WORDCLOUD_AVAILABLE:
                        st.info("Word cloud not available for this product")
                    else:
                        st.info("Install wordcloud package to see word cloud visualization")
            
            with col2:
                st.subheader("Sentiment Analytics")
                
                # Create and display sentiment charts
                sentiment_chart = create_sentiment_charts(product_sentiment, product_reviews, product)
                st.plotly_chart(sentiment_chart, use_container_width=True)
        
        else:
            st.info("💡 Customer sentiment data not available for this product. Consider gathering more customer feedback to enhance price optimization accuracy.")
        
        # Row 3: Pricing Strategy Recommendations
        st.header("🎯 Pricing Strategy Recommendations")
        
        col1, col2 = st.columns([1, 1])
        
        with col1:
            st.subheader("📈 Demand Forecast")
            
            # Create demand comparison chart
            demand_data = pd.DataFrame({
                'Scenario': ['Current Price', 'Recommended Price'],
                'Demand': [forecast['current_demand'], forecast['forecasted_demand']],
                'Price': [current_price, forecast['recommended_price']]
            })
            
            fig_demand = px.bar(
                demand_data, 
                x='Scenario', 
                y='Demand',
                title=f"Demand Forecast for {day}",
                color='Price',
                color_continuous_scale='viridis'
            )
            st.plotly_chart(fig_demand, use_container_width=True)
        
        with col2:
            st.subheader("💰 Profit Analysis")
            
            # Profit comparison
            current_profit = (current_price - cost) * forecast['current_demand']
            recommended_profit = (forecast['recommended_price'] - cost) * forecast['forecasted_demand']
            
            profit_data = pd.DataFrame({
                'Scenario': ['Current Strategy', 'Recommended Strategy'],
                'Total Profit': [current_profit, recommended_profit],
                'Units Sold': [forecast['current_demand'], forecast['forecasted_demand']]
            })
            
            fig_profit = px.bar(
                profit_data,
                x='Scenario',
                y='Total Profit',
                title=f"Profit Comparison for {day}",
                color='Total Profit',
                color_continuous_scale='RdYlGn'
            )
            st.plotly_chart(fig_profit, use_container_width=True)
            
            # Profit insights
            profit_change = recommended_profit - current_profit
            profit_change_pct = (profit_change / current_profit * 100) if current_profit > 0 else 0
            
            st.metric(
                "Profit Impact",
                f"${profit_change:+.2f}",
                delta=f"{profit_change_pct:+.1f}%"
            )
        
        # Action recommendations
        st.header("🚀 Action Recommendations")
        
        recommendations = []
        
        if price_change > 5:
            recommendations.append("📈 **Price Increase Opportunity**: Customer sentiment supports a higher price point.")
        elif price_change < -5:
            recommendations.append("📉 **Price Reduction Recommended**: Lower price could significantly boost demand.")
        else:
            recommendations.append("✅ **Current Pricing Optimal**: Maintain current pricing strategy.")
        
        if not product_sentiment.empty:
            if sentiment_score < -0.3:
                recommendations.append("⚠️ **Address Quality Issues**: Negative sentiment may impact sales. Review customer feedback.")
            elif sentiment_score > 0.5:
                recommendations.append("🌟 **Leverage Positive Sentiment**: High customer satisfaction supports premium pricing.")
        
        if forecast['forecasted_demand'] > forecast['current_demand'] * 1.2:
            recommendations.append("🎯 **High Demand Expected**: Consider inventory planning for increased sales volume.")
        
        for i, rec in enumerate(recommendations, 1):
            st.markdown(f"{i}. {rec}")
    
    else:
        # Welcome screen
        st.header("🏃‍♂️ Welcome to Nike Product Pricer")
        st.markdown("""
        ### Get AI-powered pricing recommendations with customer sentiment analysis
        
        **How it works:**
        1. 🏷️ **Select a Nike brand line** from the sidebar
        2. 👟 **Choose a product** with visual selection
        3. 📅 **Pick a day of the week** for forecasting
        4. 🚀 **Get comprehensive analysis** including:
           - Price recommendations
           - Demand forecasting
           - Customer sentiment analysis
           - Profit optimization insights
        
        **Start by selecting a brand line in the sidebar** 👈
        """)
        
        # Show sample product grid
        if not pricing_df.empty:
            st.subheader("🌟 Featured Nike Products")
            
            # Sample products
            sample_products = pricing_df.sample(min(6, len(pricing_df)))
            
            cols = st.columns(3)
            for i, (_, product) in enumerate(sample_products.iterrows()):
                with cols[i % 3]:
                    product_name = product.get('MENU_ITEM_NAME', 'Nike Product')
                    brand_name = product.get('TRUCK_BRAND_NAME', 'Nike')
                    price = product.get('PRICE', 0)
                    
                    image_url = get_product_image_url(product_name)
                    
                    st.markdown(f"""
                    <div class="product-card">
                        <img src="{image_url}" width="120" height="120" style="object-fit: cover; border-radius: 5px;">
                        <h5>{product_name}</h5>
                        <p><strong>{brand_name}</strong></p>
                        <p>${price:.2f}</p>
                    </div>
                    """, unsafe_allow_html=True)

if __name__ == "__main__":
    main()